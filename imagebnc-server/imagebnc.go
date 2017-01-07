package main

import (
	"fmt"
	"gopkg.in/ini.v1"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
)

const (
	PATH    = "imagebnc.conf"
	VERSION = 20161223
)

func main() {
	log.Printf("ImageBNC server v%v starting...\n",
		VERSION)
	if _, err := os.Stat(PATH); err != nil {
		err = writeConfig(PATH)
		if err != nil {
			log.Fatalf("Could not create a sample"+
				" config file at %v\nPlease check your permissions\n",
				PATH)
		} else {
			log.Printf("Created a sample config file at %v\n"+
				"Edit it and restart ImageBNC server\n", PATH)
			os.Exit(0)
		}
	}
	log.Println("Loading configuration...")
	c, err := loadConfig(PATH)
	if err != nil {
		log.Panicf("Could not read the config file at %v, bailing out.\n", PATH)
	}
	http.HandleFunc("/"+c.Path, func(w http.ResponseWriter, r *http.Request) {
		err := r.ParseForm()
		if err != nil {
			log.Println(err)
			return
		}
		if r.FormValue("pass") != c.Password {
			log.Printf("Somebody tried to log in with password '%v' (ip: %v, X-Forwarded-For: %v, X-Real-IP: %v)\n", r.FormValue("pass"), r.RemoteAddr, r.Header.Get("X-Forwarded-For"), r.Header.Get("X-Real-IP"))
			return
		}
		resp, err := http.Get(r.FormValue("file"))
		if err != nil {
			log.Printf("Failed to get '%v'", r.FormValue("file"))
			fmt.Fprintf(w, "failed")
			return
		}
		io.Copy(w, resp.Body)
		resp.Body.Close()
		log.Printf("Loaded '%v'", r.FormValue("file"))
	})

	log.Println("Running the server")
	log.Fatal(http.ListenAndServe(":"+c.Port, nil))

}

func loadConfig(path string) (*config, error) {
	cfg, err := ini.InsensitiveLoad(path)
	if err != nil {
		return &config{}, err
	}
	cfg.BlockMode = false
	config := new(config)
	err = cfg.Section("imagebnc").MapTo(config)
	return config, err
}

func writeConfig(path string) error {
	config := `[imagebnc]
password = p455vv0rd # the password, must be sent via 'pass' GET or POST parameter
path = bnc # path (after slash, e. g. example.org/bnc)
port = 8080 # port to listen on
`
	return ioutil.WriteFile(path, []byte(config), os.FileMode(0700))
}

type config struct {
	Password string
	Path     string
	Port     string
}
