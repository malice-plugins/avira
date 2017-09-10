package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"html/template"
	"io/ioutil"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	log "github.com/Sirupsen/logrus"
	"github.com/fatih/structs"
	"github.com/gorilla/mux"
	"github.com/malice-plugins/go-plugin-utils/database/elasticsearch"
	"github.com/malice-plugins/go-plugin-utils/utils"
	"github.com/parnurzeal/gorequest"
	"github.com/urfave/cli"
)

var (
	// Version stores the plugin's version
	Version string
	// BuildTime stores the plugin's build time
	BuildTime string

	path string
)

const (
	name     = "avira"
	category = "av"
)

type pluginResults struct {
	ID   string      `json:"id" structs:"id,omitempty"`
	Data ResultsData `json:"avira" structs:"avira"`
}

// Avira json object
type Avira struct {
	Results ResultsData `json:"avira"`
}

// ResultsData json object
type ResultsData struct {
	Infected bool   `json:"infected" structs:"infected"`
	Result   string `json:"result" structs:"result"`
	Engine   string `json:"engine" structs:"engine"`
	Updated  string `json:"updated" structs:"updated"`
	MarkDown string `json:"markdown,omitempty" structs:"markdown,omitempty"`
	Error    string `json:"error,omitempty" structs:"error,omitempty"`
}

func assert(err error) {
	if err != nil {
		log.WithFields(log.Fields{
			"plugin":   name,
			"category": category,
			"path":     path,
		}).Fatal(err)
	}
}

// AvScan performs antivirus scan
func AvScan(timeout int) Avira {

	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(timeout)*time.Second)
	defer cancel()

	results, err := utils.RunCommand(ctx, "/opt/avira/scancl", path)
	log.WithFields(log.Fields{
		"plugin":   name,
		"category": category,
		"path":     path,
	}).Debug("avira output: ", results)

	if err != nil {
		// Avira needs to have a vaild license key to work
		if err.Error() == "exit status 219" {
			return Avira{Results: ParseAviraOutput(results, errors.New("ERROR: [No license found] Initialization"))}
		}
		// Avira exits with error status 1 if it finds a virus
		if err.Error() != "exit status 1" {
			log.WithFields(log.Fields{
				"plugin":   name,
				"category": category,
				"path":     path,
			}).Fatal(err)
		} else {
			err = nil
		}
	}

	return Avira{Results: ParseAviraOutput(results, err)}
}

// ParseAviraOutput convert avira output into ResultsData struct
func ParseAviraOutput(aviraout string, err error) ResultsData {

	if err != nil {
		return ResultsData{Error: err.Error()}
	}

	avira := ResultsData{Infected: false}

	lines := strings.Split(aviraout, "\n")

	// Extract Virus string
	for _, line := range lines {
		if len(line) != 0 {
			if strings.Contains(line, "ALERT:") {
				result, err := extractVirusName(line)
				if err != nil {
					return ResultsData{Error: err.Error()}

				}
				avira.Result = result
				avira.Infected = true
			}
		}
	}
	avira.Engine = ParseAviraEngine(getEngine())
	avira.Updated = getUpdatedDate()

	return avira
}

// extractVirusName extracts Virus name from scan results string
func extractVirusName(line string) (string, error) {
	var rgx = regexp.MustCompile(`\[.*?\]`)
	rs := rgx.FindStringSubmatch(line)
	if len(rs) > 0 {
		return strings.Trim(strings.TrimSpace(rs[0]), "[]"), nil
	}
	return "", fmt.Errorf("was not able to extract virus name from: %s", line)
}

func getEngine() string {
	results, err := utils.RunCommand(nil, "/opt/avira/scancl", "--version")
	log.WithFields(log.Fields{
		"plugin":   name,
		"category": category,
		"path":     path,
	}).Debug("avira version: ", results)
	assert(err)

	return results
}

// ParseAviraEngine convert avira version into engine string
func ParseAviraEngine(aviraVersion string) string {
	var engine = ""
	for _, line := range strings.Split(aviraVersion, "\n") {
		if len(line) != 0 {
			if strings.Contains(line, "engine set:") {
				engine = strings.TrimSpace(strings.TrimPrefix(line, "engine set:"))
			}
		}
	}

	return engine
}

func getUpdatedDate() string {
	if _, err := os.Stat("/opt/malice/UPDATED"); os.IsNotExist(err) {
		return BuildTime
	}
	updated, err := ioutil.ReadFile("/opt/malice/UPDATED")
	utils.Assert(err)
	return string(updated)
}

func updateAV(ctx context.Context) error {
	fmt.Println("Updating Avira...")
	fmt.Println(utils.RunCommand(ctx, "/opt/malice/update"))
	// Update UPDATED file
	t := time.Now().Format("20060102")
	err := ioutil.WriteFile("/opt/malice/UPDATED", []byte(t), 0644)
	return err
}

func generateMarkDownTable(a Avira) string {
	var tplOut bytes.Buffer

	t := template.Must(template.New("").Parse(tpl))

	err := t.Execute(&tplOut, a)
	if err != nil {
		log.Println("executing template:", err)
	}

	return tplOut.String()
}

func printStatus(resp gorequest.Response, body string, errs []error) {
	fmt.Println(resp.Status)
}

func webService() {
	router := mux.NewRouter().StrictSlash(true)
	router.HandleFunc("/scan", webAvScan).Methods("POST")
	log.Info("web service listening on port :3993")
	log.Fatal(http.ListenAndServe(":3993", router))
}

func webAvScan(w http.ResponseWriter, r *http.Request) {

	r.ParseMultipartForm(32 << 20)
	file, header, err := r.FormFile("malware")
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		fmt.Fprintln(w, "please supply a valid file to scan")
		log.Error(err)
	}
	defer file.Close()

	log.Debug("uploaded fileName: ", header.Filename)

	tmpfile, err := ioutil.TempFile("/malware", "web_")
	if err != nil {
		log.Fatal(err)
	}
	defer os.Remove(tmpfile.Name()) // clean up

	data, err := ioutil.ReadAll(file)
	assert(err)

	if _, err = tmpfile.Write(data); err != nil {
		log.Fatal(err)
	}
	if err = tmpfile.Close(); err != nil {
		log.Fatal(err)
	}

	// Do AV scan
	path = tmpfile.Name()
	avira := AvScan(60)

	w.Header().Set("Content-Type", "application/json; charset=UTF-8")
	w.WriteHeader(http.StatusOK)

	if err := json.NewEncoder(w).Encode(avira); err != nil {
		log.Fatal(err)
	}
}

func main() {

	var elastic string

	cli.AppHelpTemplate = utils.AppHelpTemplate
	app := cli.NewApp()

	app.Name = "avira"
	app.Author = "blacktop"
	app.Email = "https://github.com/blacktop"
	app.Version = Version + ", BuildTime: " + BuildTime
	app.Compiled, _ = time.Parse("20060102", BuildTime)
	app.Usage = "Malice Avira AntiVirus Plugin"
	app.Flags = []cli.Flag{
		cli.BoolFlag{
			Name:  "verbose, V",
			Usage: "verbose output",
		},
		cli.BoolFlag{
			Name:  "table, t",
			Usage: "output as Markdown table",
		},
		cli.BoolFlag{
			Name:   "callback, c",
			Usage:  "POST results to Malice webhook",
			EnvVar: "MALICE_ENDPOINT",
		},
		cli.BoolFlag{
			Name:   "proxy, x",
			Usage:  "proxy settings for Malice webhook endpoint",
			EnvVar: "MALICE_PROXY",
		},
		cli.StringFlag{
			Name:        "elasitcsearch",
			Value:       "",
			Usage:       "elasitcsearch address for Malice to store results",
			EnvVar:      "MALICE_ELASTICSEARCH",
			Destination: &elastic,
		},
		cli.IntFlag{
			Name:   "timeout",
			Value:  60,
			Usage:  "malice plugin timeout (in seconds)",
			EnvVar: "MALICE_TIMEOUT",
		},
	}
	app.Commands = []cli.Command{
		{
			Name:    "update",
			Aliases: []string{"u"},
			Usage:   "Update virus definitions",
			Action: func(c *cli.Context) error {
				if c.GlobalBool("verbose") {
					log.SetLevel(log.DebugLevel)
				}
				return updateAV(nil)
			},
		},
		{
			Name:  "web",
			Usage: "Create a Avira scan web service",
			Action: func(c *cli.Context) error {
				if c.GlobalBool("verbose") {
					log.SetLevel(log.DebugLevel)
				}
				webService()
				return nil
			},
		},
	}
	app.Action = func(c *cli.Context) error {

		var err error

		if c.Bool("verbose") {
			log.SetLevel(log.DebugLevel)
		}

		if c.Args().Present() {
			path, err = filepath.Abs(c.Args().First())
			utils.Assert(err)

			if _, err := os.Stat(path); os.IsNotExist(err) {
				utils.Assert(err)
			}

			avira := AvScan(c.Int("timeout"))
			avira.Results.MarkDown = generateMarkDownTable(avira)

			// upsert into Database
			elasticsearch.InitElasticSearch(elastic)
			elasticsearch.WritePluginResultsToDatabase(elasticsearch.PluginResults{
				ID:       utils.Getopt("MALICE_SCANID", utils.GetSHA256(path)),
				Name:     name,
				Category: category,
				Data:     structs.Map(avira.Results),
			})

			if c.Bool("table") {
				fmt.Println(avira.Results.MarkDown)
			} else {
				avira.Results.MarkDown = ""
				aviraJSON, err := json.Marshal(avira)
				utils.Assert(err)
				if c.Bool("post") {
					request := gorequest.New()
					if c.Bool("proxy") {
						request = gorequest.New().Proxy(os.Getenv("MALICE_PROXY"))
					}
					request.Post(os.Getenv("MALICE_ENDPOINT")).
						Set("X-Malice-ID", utils.Getopt("MALICE_SCANID", utils.GetSHA256(path))).
						Send(string(aviraJSON)).
						End(printStatus)

					return nil
				}
				fmt.Println(string(aviraJSON))
			}
		} else {
			log.Fatal(fmt.Errorf("please supply a file to scan with malice/avira"))
		}
		return nil
	}

	err := app.Run(os.Args)
	utils.Assert(err)
}
