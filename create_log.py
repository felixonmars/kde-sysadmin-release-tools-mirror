#!/usr/bin/env python

import os
import subprocess

def getVersionFrom(repo):
	f = open(versionsDir + '/' + repo)
	return f.readlines()[1].strip()
	

f = open('modules.git')
#srcdir="/d/kde/src/5/"
srcdir="/home/kdeunstable/"
repos=[]

for line in f:
	line = line[:line.find(" ")]
	repos.append(line)

repos.sort()

fromVersion = "v4.14.3"
versionsDir = os.getcwd() + "/versions"

print "<script type='text/javascript'>"
print "function toggle(toggleUlId, toggleAElem) {"
print "var e = document.getElementById(toggleUlId)"
print "if (e.style.display == 'none') {"
print "e.style.display='block'"
print "toggleAElem.innerHTML = '[Hide]'"
print "} else {"
print "e.style.display='none'"
print "toggleAElem.innerHTML = '[Show]'"
print "}"
print "}"
print "</script>"

for repo in repos:
	toVersion = getVersionFrom(repo)
	os.chdir(srcdir+repo)

	p = subprocess.Popen('git fetch', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	retval = p.wait()
	if retval != 0:
		raise NameError('git fetch failed')

	p = subprocess.Popen('git rev-parse '+fromVersion, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	retval = p.wait()
	if retval != 0:
		print "<h2><a name='" + repo + "' href='http://quickgit.kde.org/?p="+repo+".git'>" + repo + "</a> <a href='#" + repo + "' onclick='toggle('ul" + repo +"', this)'>[Show]</a></h2>"
		print "<ul id='ul" + repo + "' style='display: none'><li>New in this release</li></ul>"
		continue

	p = subprocess.Popen('git diff '+fromVersion+'..'+toVersion, shell=True, stdout=subprocess.PIPE)
	diffOutput = p.stdout.readlines()
	retval = p.wait()
	if retval != 0:
		raise NameError('git diff failed', repo, fromVersion, toVersion)

	if len(diffOutput):
		p = subprocess.Popen('git log '+fromVersion+'..'+toVersion, shell=True, stdout=subprocess.PIPE)
		commit = []
		commits = []
		for line in p.stdout.readlines():
			if line.startswith("commit"):
				if len(commit) > 1 and not ignoreCommit:
					commits.append(commit)
				commitHash = line[7:].strip()
				ignoreCommit = False
				commit = [commitHash]
			elif line.startswith("Author"):
				pass
			elif line.startswith("Date"):
				pass
			elif line.startswith("Merge"):
				pass
			else:
				line = line.strip()
				if line.startswith("Merge remote-tracking branch"):
					ignoreCommit = True
				elif line.startswith("SVN_SILENT"):
					pass
				elif line.startswith("GIT_SILENT"):
					pass
				elif line.startswith("Merge branch"):
					ignoreCommit = True
				elif line:
					commit.append(line)
		# Add the last commit
		if len(commit) > 1 and not ignoreCommit:
			commits.append(commit)
		
		if len(commits):
			print "<h2><a name='" + repo + "' href='http://quickgit.kde.org/?p="+repo+".git'>" + repo + "</a> <a href='#" + repo + "' onclick='toggle(\"ul" + repo +"\", this)'>[Show]</a></h2>"
			print "<ul id='ul" + repo + "' style='display: none'>"
			for commit in commits:
				extra = ""
				changelog = commit[1]
				
				for line in commit:
					if line.startswith("BUGS:"):
						bugNumbers = line[line.find(":") + 1:].strip()
						for bugNumber in bugNumbers.split(","):
							if extra:
								extra += ". "
							extra += "Fixes bug <a href='https://bugs.kde.org/" + bugNumber + "'>#" + bugNumber + "</a>"
					elif line.startswith("BUG:"):
						if extra:
							extra += ". "
						bugNumber = line[line.find(":") + 1:].strip()
						extra += "Fixes bug <a href='https://bugs.kde.org/" + bugNumber + "'>#" + bugNumber + "</a>"
					elif line.startswith("REVIEW:"):
						if extra:
							extra += ". "
						reviewNumber = line[line.find(":") + 1:].strip()
						extra += "Code review <a href='https://git.reviewboard.kde.org/r/" + reviewNumber + "'>#" + reviewNumber + "</a>"
					elif line.startswith("CCBUG:"):
						if extra:
							extra += ". "
						bugNumber = line[line.find(":") + 1:].strip()
						extra += "See bug <a href='https://bugs.kde.org/" + bugNumber + "'>#" + bugNumber + "</a>"
					elif line.startswith("FEATURE:"):
						feature = line[line.find(":") + 1:].strip()
						if extra:
							extra += ". "
						if feature.isdigit():
							extra += "Implements feature <a href='https://bugs.kde.org/" + feature + "'>#" + feature + "</a>"
						else:
							changelog = feature
							
					elif line.startswith("CHANGELOG:"):
						raise NameError('Unhandled CHANGELOG')
				
				commitHash = commit[0]
				if not changelog.endswith("."):
					changelog = changelog + "."
				capitalizedChangelog = changelog[0].capitalize() + changelog[1:]
				print "<li>" + capitalizedChangelog + " <a href='http://quickgit.kde.org/?p="+repo+".git&a=commit&h="+commitHash+"'>Commit.</a> " + extra + "</li>"

			print "</ul>"
		retval = p.wait()
		if retval != 0:
			raise NameError('git log failed', repo, fromVersion, toVersion)
