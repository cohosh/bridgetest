-- Prints out the first remote IP address that the client sends a non-empty STUN message to
-- Usage: tshark -q <other opts> -Xlua_script:proxy-ip.lua -r <packet capture>

do
    -- Extractor definitions
    ip_addr_extractor = Field.new("ip.addr")

    stun_extractor = Field.new("stun")
    stun_username_extractor = Field.new("stun.att.username")
    stun_len_extractor = Field.new("stun.length")

    done = 0

    local function main()
        local tap = Listener.new("udp")

        function find_proxy_ip(pinfo, tvb)
            local ip_src, ip_dst = ip_addr_extractor()
            local stun = stun_extractor()

            if(stun) then
                local username = stun_username_extractor()
                local stun_len = stun_len_extractor()
                if(username and stun_len) then
                    if(tonumber(tostring(stun_len)) > 0) then
                        proxyip = tostring(ip_dst)
                        if( not (proxyip:match("%d+") == tostring(10))) then
                            print(tostring(ip_dst))
                            done = 1
                        end
                    end
                end
            end
        end


-------------------
----- tap functions
-------------------
        function tap.packet(pinfo,tvb,ip)
            if (done == 1) then
                return
            end
            find_proxy_ip(pinfo, tvb)
        end
    end
    main()
end



