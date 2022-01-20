


- [DeadSFU OBS Streaming from Azure Container using CLI -- Q4/2021](#deadsfu-obs-streaming-from-azure-container-using-cli----q42021)
  - [What You Will Learn](#what-you-will-learn)
  - [Thanks](#thanks)
  - [Create Azure Account](#create-azure-account)
  - [Stopping Instances and Costs](#stopping-instances-and-costs)
  - [Installing the Azure CLI command](#installing-the-azure-cli-command)
  - [Logging into Azure from the CLI](#logging-into-azure-from-the-cli)
  - [Creating a Resource Group](#creating-a-resource-group)
  - [Create the Container Json Template File](#create-the-container-json-template-file)
  - [Launch Your Container](#launch-your-container)
  - [Get The IP Address](#get-the-ip-address)
  - [Open DeadSFU Receive Page](#open-deadsfu-receive-page)
  - [Confirm You See The DeadSFU Viewer Page](#confirm-you-see-the-deadsfu-viewer-page)
  - [Optional: Test the OBS FTL Port](#optional-test-the-obs-ftl-port)
  - [Check OBS Version >= 27.0.1](#check-obs-version--2701)
  - [Configure a Camera or Test Source](#configure-a-camera-or-test-source)
  - [Launch OBS & Configure FTL](#launch-obs--configure-ftl)
  - [Start Streaming](#start-streaming)
  - [Cleanup: How to Stop the Container When You Are Done](#cleanup-how-to-stop-the-container-when-you-are-done)
  - [Whats Next? / Email Newsletter](#whats-next--email-newsletter)


## DeadSFU OBS Streaming from Azure Container using CLI -- Q4/2021




### What You Will Learn

This tutorial will take you through starting an Azure container running DeadSFU
which will allow you to do low-latency OBS streaming (using FTL).

You are then able to share the web page hosted on the container with friends
so they can see your video feee from OBS with sub-second latency.

### Thanks

Thanks to [CJSurret](https://github.com/scj643) for the idea, the technical know-how and, the chops to get this
all working on Azure!

### Create Azure Account

You need an Azure Account. Some Visual Studio licenses include $100 a month of free credits.
Also, in some cases you can qualify for an account with some free resources.

[Free Signup Link](https://azure.microsoft.com/en-us/free/)
I don't get anything if you signup with them, but I hope they'll re-tweet this post. 😍

*A credit card was required for my free account, but I understand the Visual Studio
bundled credit doesn't require a credit card. You'll have to confirm details)*

### Stopping Instances and Costs

Must I really say this?
ALWAYS, ALWAYS make sure to review and stop and container instances when you are done using
your instance.  Even if they don't have your credit card, you may legally be
on the hook for time used and expenses incurred if you leave instances running. Nuf' said.

### Installing the Azure CLI command 

Go here to get your AZ command installed, if you haven't already:

[Install AZ command for Azure](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

### Logging into Azure from the CLI

A simple command should pop open a browser to allow you to login:
```bash
az login
```

### Creating a Resource Group

I know very little about Azure, but it appears containers need to be launched into instance
groups, so you gotta create one.

```
az group create -l eastus2 -n Stream
az container create -g MyResourceGroup --name myalpine --image alpine:latest --ip-address public --ports 80 443
```

If it works, you'll see something like this:
```json
{
  "id": "/subscriptions/xxxxx/resourceGroups/Stream",
  "location": "eastus2",
  "managedBy": null,
  "name": "Stream",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": null,
  "type": "Microsoft.Resources/resourceGroups"
}
```

Note the *Succeeded* in the output.

### Create the Container Json Template File

Create a file, `template.json` with the following Json:

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "containerGroups_deadsfu_name": {
            "defaultValue": "deadsfu",
            "type": "String"
        }
    },
    "variables": {},
    "resources": [
        {
            "type": "Microsoft.ContainerInstance/containerGroups",
            "apiVersion": "2021-03-01",
            "name": "deadsfu",
            "location": "eastus2",
            "properties": {
                "sku": "Standard",
                "containers": [
                    {
                        "name": "deadsfu",
                        "properties": {
                            "image": "x186k/deadsfu",
                            "command": [
                                "/app/main",
                                "--http",
                                ":80",
                                "--ftl-udp-port",
                                "8085",
                                "--html",
                                "internal",
                                "--rtp-rx",
                                ":5004",
                                "--ftl-key",
                                "123-abc"
                            ],
                            "ports": [
                                {
                                    "protocol": "TCP",
                                    "port": 8084
                                },
                                {
                                    "protocol": "TCP",
                                    "port": 80
                                },
                                {
                                    "protocol": "UDP",
                                    "port": 8085
                                },
                                {
                                    "protocol": "UDP",
                                    "port": 5004
                                }
                            ],
                            "environmentVariables": [],
                            "resources": {
                                "requests": {
                                    "memoryInGB": 0.5,
                                    "cpu": 1
                                }
                            }
                        }
                    }
                ],
                "initContainers": [],
                "ipAddress": {
                        "dnsNameLabel": "changeme",
                        "ports": [
                                {
                                    "protocol": "TCP",
                                    "port": 8084
                                },
                                {
                                    "protocol": "TCP",
                                    "port": 80
                                },
                                {
                                    "protocol": "UDP",
                                    "port": 8085
                                },
                                {
                                    "protocol": "UDP",
                                    "port": 5004
                                }
                            ],
                            "type": "Public"


                },
                "restartPolicy": "Never",
                "osType": "Linux"
            }
        }
    ]
}
```

**You may need to change the `changeme` part to get your own hostname, I'm not sure what happens with conflicts.**

** You may want to change `123-abc`  to a different number-secret, like `46372-foofoo`, it's like a password, and OBS will need to have the right stream-key to work okay.**

We will pull up the IP address later, so hard to say if you need to change that or not.


### Launch Your Container

```bash
az deployment group create --name deadsfu --resource-group Stream --template-file template.json
```

Within the Json output, you should see `"provisioningState": "Succeeded",`


### Get The IP Address

```bash
az container show --resource-group Stream --name deadsfu --output table
```

You should see the IP address.

### Open DeadSFU Receive Page

Now open a browser tab to either the updated hostname, or IP address, something like:

#### Using Hostname:
`http://changeme.eastus2.azurecontainer.io/`, please fix `changeme` as noted earlier.

#### Using IP Address:
Open tab to `http://x.x.x.x` as reported from the `az container show` output, do not add a port.

### Confirm You See The DeadSFU Viewer Page

If you see the following view in your browser tab, then you have launched the SFU successfully.

<img src="image1.png" border="5" style="height:100%;width:100%;object-fit:contain">

If you got this working, you're nearly there, cool!

### Optional: Test the OBS FTL Port

Fixing `changeme`, or using an IP address, you can test to make sure the OBS/FTL port is open.
This isn't strictly necessary, but I like to sometimes double check stuff.
If this works, you will see `...Connected...`, if you don't see `...Connected...`, then you are not reaching the FTL port of the container, something isn't right.
```bash
curl -v telnet://changeme.eastus2.azurecontainer.io:8084
```

### Check OBS Version >= 27.0.1

If you don't have OVA installed, go get it:  [OBS homepage](https://obsproject.com/)
Make sure you have version 27.0.1 or greater.

### Configure a Camera or Test Source

This is really beyond this tutorial, but if you have a camera attached to your
system, I recommend you configure it as a `Video Capture Device` in the `Sources` panel.
If you don't have a camera, you might try using an image or video clip as a `Media Source`

### Launch OBS & Configure FTL

Open OBS.
Open `Settings` > `Stream`
Change `Service` to `Custom...`
Change `Server` to `ftl://hostname`   where hostname is the full hostname or IP address you retrieved.
Click `Show` to the right of `Stream Key`, and enter `123-abc` or whatever you substituted in the template.

Save the settings by hitting `OK`


### Start Streaming

Click the `Start Streaming` button.

If everything is working right, you should see your video from OBS in the browser tab.

Something kind of like this, with your video in the center:

<img src="image2.png" border="5" style="height:100%;width:100%;object-fit:contain">


Thanks to Pexels and videographer Ahmet Akpolat for image:
https://www.pexels.com/video/men-working-in-the-control-room-of-a-broadcasting-network-company-3433789/


### Cleanup: How to Stop the Container When You Are Done

Use these commands when you are done to stop and delete your container.
Please use version 2.29.0, and not 2.28.1 of the Azure cli, it's buggy.
```bash
az container stop -g Stream -n deadsfu
az container delete -y -g Stream -n deadsfu
```



###  Whats Next? / Email Newsletter 

It's up to you where to go from here!

Please subscribe to our newsletter if you'd like more content like this.


[Get the email newletter.](https://docs.google.com/forms/d/e/1FAIpQLSd8rzXabvn73YC_GPRtXZb1zlKPeOEQuHDdVi4m9umJqEaJsA/viewform)




