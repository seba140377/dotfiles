if command -v herdr >/dev/null 2>&1; then
  eval $(herdr completion zsh)

  if ! herdr plugin list 2>/dev/null | grep -q 'cloudmanic.herdr-plus'; then
    herdr plugin install cloudmanic/herdr-plus --yes
  fi
fi
