${DIR_CERTS} = ".\certs"
New-Item -Force "${DIR_CERTS}" -ItemType Directory
Push-Location "${DIR_CERTS}"
(Get-ChildItem -Path Cert:\CurrentUser | wsl -e sed -n "/Name/{s/.*: //g;p;}") | ForEach-Object {
  ${sub} = "${_}" -replace " ", ""
  ${path} = "Cert:\CurrentUser\${_}"
  echo "Dumping keys from ${path}"
  try {
  (Get-ChildItem -Path "${path}" | wsl -e sed -n "/^[A-F0-9]\{40\}/{s/\([A-F0-9]\{40\}\).*/\1/g;p;}") | ForEach-Object {
      ${key} = "${_}"
      ${cert} = Get-ChildItem -Path "${path}\${key}"
      ${file} = ".\${sub}_${key}.cer"
      echo "Exporting ${key} to ${file}"
      Export-Certificate -Cert ${cert} -FilePath "${file}" -Type CERT
    }
  }
  catch {
    echo "Unable to get keys for ${path}"
  }
}
Pop-Location
