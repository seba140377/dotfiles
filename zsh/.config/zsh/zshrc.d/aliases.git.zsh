alias gst='git status'
alias gco='git checkout'
alias gcm='git commit'
alias gp='git push'
alias gl='git log'

function gac() {
	git add .

	if [ -z "$1" ]; then
		nano /tmp/commit_msg.txt
		if [ -s /tmp/commit_msg.txt ]; then
			git commit -F /tmp/commit_msg.txt
			rm /tmp/commit_msg.txt
		fi
	else
		git commit -m "$1"
	fi
}

function gacp() {
	git add .

	if [ -z "$1" ]; then
	    nano /tmp/commit_msg.txt
		if [ -s /tmp/commit_msg.txt ]; then
			git commit -F /tmp/commit_msg.txt
			rm /tmp/commit_msg.txt
		fi
	else
		git commit -m "$1"
	fi

	git push
}
