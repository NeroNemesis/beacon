# syntax=docker/dockerfile:1
# Build en 2 étapes : le SDK compile, l'image finale ne contient que le runtime.
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
# On copie d'abord le .csproj seul : la couche "restore" est mise en cache tant que les dépendances ne changent pas.
COPY src/Beacon.Api/Beacon.Api.csproj src/Beacon.Api/
RUN dotnet restore src/Beacon.Api/Beacon.Api.csproj
COPY src/ src/
RUN dotnet publish src/Beacon.Api/Beacon.Api.csproj -c Release -o /app/publish --no-restore /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
# Les images .NET définissent APP_UID : on ne tourne jamais en root.
USER $APP_UID
EXPOSE 8080
ENTRYPOINT ["dotnet", "Beacon.Api.dll"]
