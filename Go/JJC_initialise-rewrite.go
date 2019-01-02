/*
 * In my JJC Docker project I wrote a python script that
 * created / tore down everything required to run the
 * docker-compose file; this script is a rewrite in Go
 */

package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

var (
	composeFile = "docker-compose.yml"
	rootHost    = "testdomain.com"
	volumeList  = make([]string, 0)
	hostList    = make([]string, 0)
)

/*
 * FUNCTIONS
 */

func check(caller string, e error) {
	if e != nil {
		fmt.Println("PANIC! func " + caller + " encountered a problem:\n")
		panic(e)
	}
}

func getVolumes(filename string) (listHosts []string, listVols []string) {
	// Process the passed file and looks for the 'volumes:' section, returning
	// a list of its contents. This func has been expanded to also return a
	// list of hostnames, since we'll need those as well
	sectionVolumes := false
	file, err := os.Open(filename)
	check("getVolumes", err)
	defer file.Close()
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if len(line) > 0 { // strings.Contains panics if line is empty!
			if strings.Contains(line, "hostname: ") {
				if strings.Contains(line, rootHost) {
					listHosts = append(listHosts, line[14:])
				}
			} else if line == "volumes:" {
				// Starting the VOLUMES section we're after
				sectionVolumes = true
			} else if line[:1] != " " {
				// Start of an irrelevant section
				sectionVolumes = false
			} else if sectionVolumes {
				// This line's relevant for VOLUMES processing
				listVols = append(listVols, line[2:len(line)-1])
			}
		}
	}
	check("getVolumes(2)", scanner.Err())
	return listVols, listHosts
}

func mkVolumes(list []string) {
	// Takes a list of docker volumes and creates the relevant subdirectories
	fmt.Println("mkVolumes: ", list)
	for _, name := range list {
		if _, err := os.Stat(name); os.IsNotExist(err) {
			os.Mkdir(name, 0755)
			fmt.Println("Created DIR '", name, "'")
		}
	}
}

func rmVolumes(list []string) {
	// Takes a list of subdirectories that were created for docker volumes
	// and removes them
	for _, name := range list {
		if _, err := os.Stat(name); err == nil {
			os.RemoveAll(name)
			fmt.Println("Removed DIR '", name, "'")
		}
	}
}

func addHosts(list []string) {
	// Scans our /etc/hosts file and appends any FQDNs that were found in
	// our docker-compose file. It then writes the new file to a temporary
	// location before using that to overwrite /etc/hosts
	oldFile, err := os.Open("/etc/hosts")
	check("addHosts READ", err)
	defer oldFile.Close()
	newFile, err := os.Create("newhosts")
	check("addHosts WRITE", err)
	defer newFile.Close()
	scanner := bufio.NewScanner(oldFile)
	for scanner.Scan() {
		line := scanner.Text()
		if len(line) > 0 {
			newFile.WriteString(line + "\n")
			fmt.Println(line)
		}
	}
	for _, name := range list {
		fmt.Println("Adding host: ", name)
		newFile.WriteString("127.0.0.1\t" + name + "\n")
	}
	newFile.Sync()
	mvHostsFile()
}

func mvHostsFile() {
	// Now that the new hosts file is written, move it into place
	fmt.Println("Moving generated hosts file to proper location ...")
	out, err := exec.Command("sudo", "mv", "newhosts", "/etc/hosts").Output()
	check("addHosts MOVE", err)
	output := string(out[:])
	fmt.Println(output)
}

func rmHosts(list []string) {
	// Scans /etc/hosts and removes any hostnames that were found in our
	// docker-compose.yml file; it writes everything else to a temporary file,
	// which is then uses to overwrite /etc/hosts
	oldFile, err := os.Open("/etc/hosts")
	check("addHosts READ", err)
	defer oldFile.Close()
	newFile, err := os.Create("newhosts")
	check("addHosts WRITE", err)
	defer newFile.Close()
	scanner := bufio.NewScanner(oldFile)
	for scanner.Scan() {
		line := scanner.Text()
		lineNeeded := true
		for _, name := range list {
			if strings.Contains(line, name) {
				fmt.Println("REMOVING ", line, " : matches ", name)
				lineNeeded = false
			}
		}
		if lineNeeded {
			if len(line) > 0 {
				fmt.Println("Writing ", line)
				newFile.WriteString(line + "\n")
				fmt.Println(line)
			}
		}
	}
	newFile.Sync()
	mvHostsFile()
}

/*
 * MAIN function
 */

func main() {
	command := ""
	if len(os.Args) > 1 {
		command = os.Args[1]
	}
	volumeList, hostList := getVolumes(composeFile)
	if command == "UP" {
		fmt.Println("Setting up environment ...")
		mkVolumes(volumeList)
		addHosts(hostList)
		fmt.Println("Running docker-compose ...")
		out, err := exec.Command("docker-compose", "up", "-d").Output()
		check("MAIN docker-up", err)
		output := string(out[:])
		fmt.Println("MAIN: ", output)
	} else if command == "DOWN" {
		fmt.Println("Stopping docker-compose ...")
		out, err := exec.Command("docker-compose", "down").Output()
		check("MAIN docker-down", err)
		output := string(out[:])
		fmt.Println("MAIN: ", output)
		fmt.Println("Cleaning up environment ...")
		rmVolumes(volumeList)
		rmHosts(hostList)
	} else {
		fmt.Println("Invalid argument: use UP or DOWN")
	}
}
