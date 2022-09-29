package main

import (
	"fmt"
	"io/ioutil"
	"math/rand"
	"reflect"

	"gopkg.in/yaml.v2"
)

func checkError(e error) {
	if e != nil {
		panic(e)
	}
}

type Dialog struct {
	Abomination  map[string]string `yaml:"abomination"`
	Antiquarian  map[string]string `yaml:"antiquarian"`
	Arbalest     map[string]string `yaml:"arbalest"`
	BountyHunter map[string]string `yaml:"bounty_hunter"`
	Crusader     map[string]string `yaml:"crusader"`
	GraveRobber  map[string]string `yaml:"grave_robber"`
	Hellion      map[string]string `yaml:"hellion"`
	Highwayman   map[string]string `yaml:"highwayman"`
	Houdmaster   map[string]string `yaml:"houdmaster"`
	Houndmaster  map[string]string `yaml:"houndmaster"`
	Jester       map[string]string `yaml:"jester"`
	Leper        map[string]string `yaml:"leper"`
	ManAtArms    map[string]string `yaml:"man_at_arms"`
	Musketeer    map[string]string `yaml:"musketeer"`
	Occultist    map[string]string `yaml:"occultist"`
	PlagueDoctor map[string]string `yaml:"plague_doctor"`
	Vestal       map[string]string `yaml:"vestal"`
	Rest         map[string]string `yaml:"rest"`
}

func GetMapRandomValue(m map[string]string) string {
	keys := reflect.ValueOf(m).MapKeys()

	return m[keys[rand.Intn(len(keys))].String()]
}

func main() {
	bytes, err := ioutil.ReadFile("data/dialog.yaml")
	checkError(err)

	d := &Dialog{}
	err = yaml.Unmarshal(bytes, &d)
	checkError(err)

	fmt.Println(GetMapRandomValue(d.Abomination))
}
