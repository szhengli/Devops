package config

import (
	"fmt"
	etcdCfg "github.com/go-micro/plugins/v4/config/source/etcd"
	"github.com/pkg/errors"
	"go-micro.dev/v4/config"
	"go-micro.dev/v4/logger"
)

type Config struct {
	Addr string
	Name string
}

var _cfg = &Config{
	Addr: ":7089",
	Name: "shop2",
}

func Get() Config {
	return *_cfg
}

func Load() error {
	etcdSource := etcdCfg.NewSource(
		etcdCfg.WithAddress("192.168.2.89:2379"),
	)
	conf, _ := config.NewConfig()

	err := conf.Load(etcdSource)
	if err != nil {
		return errors.Wrap(err, "fail to load config from etcd...")
	}
	if err := conf.Get("micro", "config", "shop").Scan(_cfg); err != nil {
		return errors.Wrap(err, "conf.Scan")
	}else {
		fmt.Println("scan and configed !!!!!!!")
	}

	w, _ := conf.Watch("micro", "config", "shop")
	go func() {
		for {
			v, _ := w.Next()

			//v.Scan(&host)

			fmt.Println("!!!!!!!!!!!!!!!")

			if err := v.Scan(_cfg); err != nil {
				logger.Error(err)
				return
			}

			fmt.Println(*_cfg)

			fmt.Println("!!!!!!!!!!!!!!!")
		}
	}()

	return nil
}
