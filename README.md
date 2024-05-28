# Helm Chart example for deploying the GREN Map
This chart serves and an example for deploying the GREN Map project using [Helm](https://helm.sh/) in [Kubernetes](https://kubernetes.io/) (K8s). Please note this is an example to build off of, not a full how-to guide. It describes the quick start steps to run the map using locally built containers and the IdP from the development environment.

For more detailed information about the Docker compose development environment for the GREN Map project, please see [GREN Map DB Node](https://github.com/grenmap/GREN-Map-DB-Node/tree/main/docs/index.md).

This example uses [Shibboleth Single Sign-on (SSO)](https://incommon.org/software/shibboleth/) for user authorization. Please contact your local [Federation/IdP provider](https://technical.edugain.org) to integrate with with your local production federation.

This project makes use of the [InCommon IdP and SP](https://hub.docker.com/u/i2incommon) containers.

# Background Skill and Knowledge
This example assumes a familiarity with the following technologies to transition it into a production deployment.

* [Kubernetes](https://kubernetes.io/)
* [Kubernetes with Docker Desktop](https://www.docker.com/blog/how-kubernetes-works-under-the-hood-with-docker-desktop/)
* [Helm](https://helm.sh/)
* [Shibboleth Single Sign-on (SSO)](https://incommon.org/software/shibboleth/)
* [Shibboleth Service Provider](https://shibboleth.atlassian.net/wiki/spaces/SP3/overview)
* [PostgreSQL](https://www.postgresql.org/)

# Quickstart Guide
This section details how to quickly get started with running the map via Helm on a development computer. It is assuming a Mac environment running on Apple Silicon. Please make local adjustments for other operating systems. (The configuration below should auto set `DOCKER_BUILD_PLATFORM` in the environment. If not, see the Troubleshooting section at the end of the document.)

### Docker Desktop Setup
For this example the built in [Docker Desktop Kubernetes](https://docs.docker.com/desktop/kubernetes/) cluster has been chosen as it is ubiquitous and simple to run. It is not configured by default though, so it needs turning on. 

First ensure your Docker Desktop installation is up-to-date. Then, as of the time of writing, follow this procedure.
1. Open Docker Desktop
1. Click the 'cog' icon in the top right for the Settings page
1. Select 'Kubernetes' from the left menu
1. Check 'Enable Kubernetes'
1. Click the 'Apply & restart' button
1. Check that Kubernetes is running healthily in Docker Desktop — Lower left, Kubernetes button is green.

### Helm Setup
This example also requires Helm to be installed. If you are running on a Mac the simplest way is through [Brew](https://brew.sh/), the [Helm](https://helm.sh/docs/intro/install/) website has options for other operating systems  and more advanced instruction.
```bash
   brew install helm
```

## Preparation
There are two preparation steps to perform to before we can dive into the K8s specific steps to run the application.

Firstly as we are running on a local development machine we need to override the `/etc/hosts` file to direct the hostnames we will be using to localhost. In this quick start we will be using `map.example.org` as the hostname for the GREN map instance and `idp.example.org` as the IdP hostname. Please add the following to `/etc/hosts`.
```
127.0.0.1   map.example.org idp.example.org
```

Secondly we need to build and configure the development containers so they contain the correct bi-lateral trust for SSO authentication. In the GREN map we use Shibboleth as the authentication technology. When deploying in production there should be a metadata exchange with your local federation where the trust is setup and configured. For this local demonstration of using Helm to deploy a map instance, we can use the InCommon IdP container from the development environment.

This step sets up the GREN development environment to build the containers. In short this script will pull the main GREN map repository, apply some bespoke environment settings, perform metadata exchange so the development IdP trusts the SP, generate key and certificate files, build the containers and run the IdP.

This script takes a while as it clones the development directory and builds containers for the map application, SP and IdP. See the script for more details.
```
   cd demo-config
   ./configure.sh
```

Please note: the IdP is run as a daemon, to stop it you can run `docker compose -f docker-compose.idp.yml down` from the repository directory that was cloned, typically `demo-config/GREN-Map-DB-Node`.

## Running with Helm
Now that we have the preparation out of the way we can follow the Kubernetes and Helm specific steps to run the example.

### Kubernetes Secret Configuration
The SP chart relies on having the certificate & key files and the database authentication available as secrets. For this demo we will configure these as opaque secrets in Kubernetes.

The certificate files were generated and copied to the main Helm directory as part of the configuration in the Preparation step above. 

First ensure you are in the repository root directory then run the [kubectl](https://kubernetes.io/docs/reference/kubectl/) commands below to create the secrets for the deployment.

```bash
    kubectl create secret generic websp-keys-certs --from-file=websp-host-cert=host-cert.pem --from-file=websp-host-key=host-key.pem --from-file=websp-sp-cert=sp-cert.pem --from-file=websp-sp-key=sp-key.pem
```

The passwords for the PostgreSQL database are also provided to the chart as an opaque secret called `postgres-passwd-and-secret-key`. 
```bash
    kubectl create secret generic postgres-passwd-and-secret-key --from-literal=postgres_passwd='change_me_please' --from-literal=secret_key='change_me_please'
```

### Is the IdP running?
Before we run the map let's make sure the IdP we started earlier is running:
```
   docker ps
```

The `gren-map-db-node-idp` container should show as `(healthy)`.

### Install the Helm chart
Deploy the chart with default values.yaml in the chart folder. For detailed information about Helm see the [documentation](https://helm.sh/docs/).

```bash
    helm install grenmap .
```

Once this is done we can check that all of the containers are up using:
```bash
    kubectl get pods
```

They should all show as running with similar output to this. It may take a few seconds for all of the containers to be fully ready.
```
NAME                                  READY   STATUS    RESTARTS   AGE
app-547bd799c5-pttvl                  1/1     Running   0          27s
grenmap-db-79f5cd8895-pzc87           1/1     Running   0          27s
grenmap-taskrunner-56669bdd7c-csd2v   1/1     Running   0          27s
grenmap-websp-97b78f786-fj9nh         1/1     Running   0          27s
redis-c47745bd9-5vv6q                 1/1     Running   0          27s
```

### View the map!
Browse to https://map.example.org:30443 to see the map. Please note that in this example we are using self-signed certificates. Your browser will warn you that the site is 'untrusted' when you first browse to either the map or the IdP. You can continue by 'accepting the risk'.

You should see an empty map of the world with a 'GREN' logo in the top left-and corner.

#### Log in
Select `Login` from the top right of the map page, this will then take you to an embedded discovery service page where you can use `Allow me to pick from a list` to select the example IdP. Select it and click `Continue` to log in. 

For this example in the `values.yaml` file one user has been configured as an instance administrator. This user has been configured in the `demo-config/users.ldif` files with the credentials `admin/admin`. When you log in as this user you are given the permissions of an instance admin. 

In the top right of the screen there will now be two options `Admin` and `Log out`. Selecting Admin will take you to the configuration page where content can be added to the map.

Another user has been configured in the `demo-config/users.ldif` file, this is a regular user that has not been set up as an instance administrator. The user is able to log in BUT has no access beyond viewing the map like a non-authenticated user.

### Cleanup

To stop the GREN map instance run:

```
   helm uninstall grenmap
```

In the demo-config folder there is also a script that will cleanup after running the map.

**PLEASE NOTE** This will delete the secrets, delete all of the key and certificates files, stop the IdP and delete the development environment repository folder.
```
   ./clean.sh
```

# Troubleshooting

## Docker containers fail to run or build
Occasionally Docker seems to get a little confused and no matter how much you rebuild with `--no-cache` it can fail to pick up changes. One option when this happens is to prune Docker. Be aware that this will remove all all docker images, containers and volume mounts.
```
   docker system prune -a --volumes
```

It may be that a build is failing to run on your system. The `./configure.sh` script will try to auto detect your platform type and configure the correct environment platform for building docker containers. If this is not working then you can set it manually by ensuring that the `DOCKER_DEFAULT_PLATFORM` variable is set correctly for your platform:
```
   # Environment variables for platform build
   DOCKER_DEFAULT_PLATFORM=linux/amd64 # use this version for Intel based systems
   # DOCKER_DEFAULT_PLATFORM=linux/arm64  # use this version for Apple Silicon ARM-based systems
```
The script will not do anything if this variable is already set.

## Docker Desktop configuration
Docker Desktop should install `kubectl` when Kubernetes is configured. If for some reason, after a reboot, kubectl is not installed then it can be installed directly. For example via `brew`:
```
   brew install kubectl
```

# Advanced
The Quickstart section contained very simple basic instructions for getting the map running on a local Kubernetes cluster via Docker Desktop. This section contains more details for alternate deployments. It relies on the reader having a more thorough understanding of the technologies involved.

## Configuration options

### Use a custom logo for Embedded Discovery Service (EDS)
To use a different logo image for EDS, replace the default image file of "eds_logo.png" under `./charts/websp/images/` with a similarly dimensioned and sized image.

Update the related field in the top-level `values.yaml`.
```
  eds_logo: 'images/eds_logo.png'
```

### Docker images from a private repository
This example made use of locally built images. If you are building and storing images in a private repository (as of the time of writing there is no public repository for the images, although is is a future plan). You can update the `values.yaml` file to pull the image. Replace `<REPOSITORY_LOCATION>` with the registry address of your containers.
```bash
  image:
    repository: <REPOSITORY_LOCATION>
    tag: "latest"
    imagePullPolicy: Always
```

Create an [imagePullSecrets](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)  to allow access to the private registry.

Add this to `values.yaml` and replace the "apps-registry" with the secret created above for the related image.
```bash
  imagePullSecrets:
    - name: apps-registry
```

## Kind
It is possible to run this on [Kind](https://kind.sigs.k8s.io/) as a backend Kubernetes cluster. This will involve configuring nginx as an ingress controller. More information can be found here.

- https://kind.sigs.k8s.io/docs/user/ingress/
- https://kind.sigs.k8s.io/docs/user/quick-start/

## Deployment for production on Rancher
In our production instance we are using Rancher for the Kubernetes cluster. The `values_remote.yaml` files provides a an example of how the Helm chart might need modifying to run there. The rough steps are:

1. Create a Namespace for the map instance, continue on the following steps with this namespace.
2. Create secrets for chart repository, docker image registry.
3. Add the chart repository to Repositories.
4. Deploy the related chart.

## Create the new secrets for the SP
If new secrets are required for the SP or for deploying in a production environment the following steps show how this can be done.

To generate `sp-key.pem` and `sp-cert.pem` for shibboleth (replace "map.example.org" with the real host name):

In the helm chart dir
```bash
   ./charts/websp/shibboleth_keygen.sh -f -h map.example.org -y 10 -n sp
```

Use the following command to generate `host-key.pem` and `host-cert.pem` for apache (replace "map.example.org" with the real host name):

```bash
   ./charts/websp/shibboleth_keygen.sh -f -h map.example.org -y 10 -n host
```
