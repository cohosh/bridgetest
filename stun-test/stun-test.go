package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/pion/stun"
)

var defaultSTUNServers = []string{
	"stun.l.google.com:19302",
	"stun.voip.blackberry.com:3478",
	"stun.altar.com.pl:3478",
	"stun.antisip.com:3478",
	"stun.bluesip.net:3478",
	"stun.dus.net:3478",
	"stun.epygi.com:3478",
	"stun.sonetel.com:3478",
	"stun.sonetel.net:3478",
	"stun.stunprotocol.org:3478",
	"stun.uls.co.za:3478",
	"stun.voipgate.com:3478",
	"stun.voys.nl:3478",
}

func main() {
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage of %s:\n", os.Args[0])
		fmt.Fprintln(os.Stderr, os.Args[0], "[path]")
	}
	flag.Parse()
	path := flag.Arg(0)
	if path == "" {
		path = "."
	}
	path = fmt.Sprintf("%s/stun-test.csv", path)

	f, err := os.OpenFile(path, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0600)
	if err != nil {
		panic(err)
	}

	for _, server := range defaultSTUNServers {
		res := testServer(server)
		if _, err := f.Write([]byte(res)); err != nil {
			panic(err)
		}

	}
	f.Close()
}

func testServer(addr string) string {
	c, err := stun.Dial("udp", addr)
	if err != nil {
		return fmt.Sprintf("%s,false,dial,%s\n", addr, err.Error())
	}
	if err = c.Do(stun.MustBuild(stun.TransactionID, stun.BindingRequest), func(res stun.Event) {
		if res.Error != nil {
			return
		}
		var xorAddr stun.XORMappedAddress
		if getErr := xorAddr.GetFrom(res.Message); getErr != nil {
			return
		}
		fmt.Println(xorAddr)
	}); err != nil {
		return fmt.Sprintf("%s,false,request,%s\n", addr, err.Error())
	}
	c.Close()
	return fmt.Sprintf("%s,true,,\n", addr)
}
