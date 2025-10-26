function gac() {
	if [ -z "$1" ]; then
	  echo "❗Missing commit message"
		echo "  Usage: gac \"<commit message>\""
		return 1
	fi
	git add .
	git commit -m "$1"
}

function gacp() {
	if [ -z "$1" ]; then
	  echo "❗Missing commit message"
		echo "  Usage: gacp \"<commit message>\""
		return 1
	fi
	git add .
	git commit -m "$1"
	git push
}
