FROM mcr.microsoft.com/powershell:latest
RUN ["pwsh", "-Command", "Set-PSRepository", "-Name", "PSGallery", "-InstallationPolicy", "Trusted"]
RUN ["pwsh", "-Command", "Install-Module", "-Name", "VMware.PowerCLI", "-Force"]
RUN ["pwsh", "-Command", "Set-PowerCLIConfiguration", "-Scope", "User", "-Participate", "$false", "-Confirm:$false"]
RUN ["pwsh", "-Command", "Set-PowerCLIConfiguration", "-InvalidCertificateAction", "Ignore", "-Confirm:$false"]
RUN ["apt-get", "update"]
RUN ["apt-get", "-y", "install", "curl"]
CMD pwsh