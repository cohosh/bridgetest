-- Prints out the first remote IP address that the client sends a non-empty STUN message to
-- Usage: tshark -q <other opts> -Xlua_script:proxy-ip.lua -r <packet capture>

do
    -- Extractor definitions
    ip_addr_extractor = Field.new("ip.addr")
    ipv6_addr_extractor = Field.new("ipv6.addr")

    -- STUN fields
    stun_extractor = Field.new("stun")
    stun_username_extractor = Field.new("stun.att.username")
    stun_len_extractor = Field.new("stun.length")
    stun_response_extractor = Field.new("stun.att.port-xord")
    stun_type_extractor = Field.new("stun.type")

    -- DNS
    dns_extractor = Field.new("dns")
    dns_ipv4_response_extractor = Field.new("dns.a") -- IPv4
    dns_ipv6_response_extractor = Field.new("dns.aaaa") -- IPv6
    dns_response_name_extractor = Field.new("dns.resp.name")

    -- TLS
    tls_extractor = Field.new("ssl")
    tls_success_extractor = Field.new("ssl.app_data")
    dtls_extractor = Field.new("dtls")
    dtls_success_extractor = Field.new("dtls.app_data")

    -- Constants
    STUN_RESPONSE = "0x00000101"

    -- Global variables
    stage = "Gathering"
    peer_candidates = {}
    print("stage:"..stage)

    local function main()
        local ipv4_tap = Listener.new("ip")
        local ipv6_tap = Listener.new("ipv6")

        function process_packet(pinfo, tvb)
            local ip_src, ip_dst = ip_addr_extractor()
            local stun = stun_extractor()

            if (stage == "Gathering") then
                gathering_phase()
            elseif (stage == "Signaling") then
                signaling_phase()
            elseif (stage == "Connecting") then
                connecting_phase()
            elseif (stage == "Data") then
                data_phase()
                connecting_phase() --still sending connect information
            end

        end

        function gathering_phase()
            --looking for connection to STUN server
            if(dns_extractor()) then
                local stun_server = dns_response_name_extractor()
                local stun_ipv4_addr = dns_ipv4_response_extractor()
                local stun_ipv6_addr = dns_ipv6_response_extractor()
                if (stun_ipv4_addr) then
                    stun_ipv4 = tostring(stun_ipv4_addr)
                    print("Received v4 address for STUN server "..tostring(stun_server)..": "..tostring(stun_ipv4_addr))
                end
                if (stun_ipv6_addr) then
                    stun_ipv6 = tostring(stun_ipv6_addr)
                    print("Received v6 address for STUN server "..tostring(stun_server)..": "..tostring(stun_ipv6_addr))
                end
            end

            if(stun_ipv4 or stun_ipv6) then
                --check if we've received a Binding success response
                if(stun_extractor() and stun_response_extractor()) then
                    local ip_src, ip_dst = ip_addr_extractor()
                    if( (tostring(ip_src) == stun_ipv4) or (tostring(ip_src) == stun_ipv6)) then
                        print("Received STUN success response from "..tostring(ip_src))
                        stage = "Signaling"
                        print("stage:"..stage)
                    end
                end
            end
        end

        function signaling_phase()
            --looking for connection to domain-fronted snowflake broker
            if(dns_extractor()) then
                local broker = dns_response_name_extractor()
                local broker_ipv4_addr = dns_ipv4_response_extractor()
                local broker_ipv6_addr = dns_ipv6_response_extractor()
                if (broker_ipv4_addr) then
                    broker_ipv4 = tostring(broker_ipv4_addr)
                    print("Received v4 address for Broker front "..tostring(broker)..": "..tostring(broker_ipv4_addr))
                end
                if (broker_ipv6_addr) then
                    broker_ipv6 = tostring(broker_ipv6_addr)
                    print("Received v6 address for Broker front "..tostring(broker)..": "..tostring(broker_ipv6_addr))
                end
            end

            if(broker_ipv4 or broker_ipv6) then
                --look or successfull TLS handshake
                local ip_src, ip_dst = ip_addr_extractor()
                if( (tostring(ip_src) == broker_ipv4) or (tostring(ip_dst) == broker_ipv6)) then
                    isTLS = tls_extractor()
                    isTLSsuccess = tls_success_extractor()
                    if(isTLS and isTLSsuccess) then
                        print("Received signaling data from "..tostring(ip_src))
                        stage = "Connecting"
                        print("stage:"..stage)
                    end
                end
            end

        end

        function connecting_phase()
            --looking for connection to snowflake peer
            local isSTUN = stun_extractor()
            local stun_username = stun_username_extractor()
            local stun_type = stun_type_extractor()
            local _, ip_dst = ip_addr_extractor()
            if (not ip_dst) then
                ip_dst = ipv6_addr_extractor()
            end

            if(isSTUN and stun_username) then
                local names = string_split(tostring(stun_username), ":")
                if (not myname) then
                    myname = names[1]
                    peername = names[2]
                end
                if (names[1] == myname) then
                    if (not peer_candidates[tostring(ip_dst)]) then
                        print("Sent Binding request with username "..tostring(stun_username).. " to peer candidate "..tostring(ip_dst))
                        peer_candidates[tostring(ip_dst)] = "sent"
                    end
                end
            end

            if(isSTUN and tostring(stun_type) == STUN_RESPONSE) then
                if (peer_candidates[tostring(ip_dst)] == "sent") then
                    print("Received Success Response from peer candidate "..tostring(ip_dst))
                    peer_candidates[tostring(ip_dst)] = "success"
                    if (stage == "Connecting") then
                        stage = "Data"
                        print("stage:"..stage)
                    end
                end
            end

        end

        function data_phase()
            --looking for dtls with snowflake peer
            local ip_src, _ = ip_addr_extractor()
            if (not ip_src) then
                ip_src = ipv6_addr_extractor()
            end
            if( peer_candidates[tostring(ip_src)] == "success") then
                isDTLS = dtls_extractor()
                if(isDTLS and dtls_success_extractor()) then
                    print("Successfully connected to snowflake "..tostring(ip_src))
                    stage = "Done"
                    print("stage:"..stage)
                end
            end

        end


        function string_split(inputstr, sep)
            if sep == nil then
                sep = "%s"
            end
            local t={}
            for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
            end
            return t
        end

-------------------
----- tap functions
-------------------
        function ipv4_tap.packet(pinfo,tvb,ip)
            process_packet(pinfo, tvb)
        end
        function ipv6_tap.packet(pinfo,tvb,ipv6)
            process_packet(pinfo, tvb)
        end
    end
    main()
end
