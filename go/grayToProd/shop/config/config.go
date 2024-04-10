package config

import (
	"fmt"
	etcdCfg "github.com/go-micro/plugins/v4/config/source/etcd"
	"github.com/pkg/errors"
	"go-micro.dev/v4/config"
)

type Config struct {
	Port       int
	Helloworld string
}

var cfg *Config = &Config{
	Port:       7089,
	Helloworld: "helloworld",
}

func Get() Config {
	return *cfg
}

func Address() string {
	return fmt.Sprintf(":%d", cfg.Port)
}

type Host struct {
	Address string `json:"address"`
	Port    int    `json:"port"`
}

var host Host

func Load() error {
	etcdSource := etcdCfg.NewSource(
		etcdCfg.WithAddress("192.168.2.89:2379"),
	)
	conf, _ := config.NewConfig()

	err := conf.Load(etcdSource)
	if err != nil {
		return errors.Wrap(err, "fail to load config from etcd...")
	}
	w, _ := conf.Watch("micro", "config")
	go func() {
		for {
			v, _ := w.Next()

			//v.Scan(&host)

			fmt.Println("!!!!!!!!!!!!!!!")
			fmt.Println(string(v.Bytes()))
			v.Scan(&host)

			cfg.Port = host.Port

			fmt.Println("!!!!!!!!!!!!!!!")
		}
	}()

	return nil
}
