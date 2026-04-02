# Oracle UDP Reverse Tunnel Setup

All credit for the original work goes to [@prof7bit](https://github.com/prof7bit), this is by all means an addition to his work to make it a little easier to set up.

## Initial Setup (Oracle Side)

#### Requirements

1. Oracle Cloud Account, you can sign up for a free account [here](https://www.oracle.com/cloud/free/). (We will set up your "outside" server here)
2. A Linux instance to serve as your "inside" server. (The machine that you want to send traffic to)
3. A SSH client of some sort, I recommend [PuTTY](https://www.putty.org/).

### Creating an Instance on Oracle Cloud

1. Navigate to `Compute > Compute > Instances` in the hamburger menu, and click `Create instance`
2. Give it a `name` of your choice, select any `availability domain`, and leave everything else as default. (You can change the OS if you want but I recommend sticking with `Oracle Linux`)
3. Leave `Security` as is, next.
4. For Networking, give the VNIC a name of your choosing, select `Create new virtual cloud network` and `Create new public subnet`, name them both. Scroll to `Add SSH keys` select `Generate a key pair for me` if it is not already selected, and click `Download private key`. This will download the key as `ssh-key-YYYY-MM-DD.key`. 
5. Save the key somewhere safe as you will need it to connect to your instance. Click `Next`.
6. Leave the settings in `Storage` as default and click `Next`.
7. Review your settings and click `Create`.

### Setting up a Reserved Public IP

In order for all of this to work, you need a static public IP address. By default Oracle assigns a rotating public IP to the instance, which will break your tunnel every time it changes. We will avoid this by reserving a public IP, and assigning it to our instance.

1. Navigate to `Network > IP management > Reserved public IPs` in the hamburger menu, and click `Reserve public IP address`.
2. Give it a name of your choice, and click `Reserve public IP address`.`
3. Go back to `Compute > Compute > Instances`, click on the instance you just created. Select `Networking`, and click on the name of the VNIC you created earlier. 
4. Click `IP administration`, then the three dots on the far right of the only IP address listed, and select `Edit`.
5. At this point there is one of two options, if you have used Oracle in the past, and have used public IP addresses, you may have an `Ephemeral public IP` already selected, if this is the case set the state to `No public IP` and click `Update`. 
6. Once you no longer have an `Ephemeral public IP` selected, or didn't to begin with, select `Reserved public IP`, and select the reserved public IP you just created, then click `Update`.

### Firewall Rules

Because Oracle by default blocks all incoming traffic, besides SSH, we need to open the port we want to use for our tunnel.

1. Navigate back to the `Details` page of your VNIC, and click the name of your `Subnet`.
2. Click `Security`, then under `Security lists` click the name of the default security list.
3. Select `Security rules`, and click `Add Ingress Rules`.
4. Leave the `Source type` as `CIDR`, and set the `Source CIDR` to `0.0.0.0/0`. Set the `IP Protocol` to `UDP`, and set the `Destination port range` to the port you want to allow. 
5. For the purpose of this tutorial we will use port `51820`, the default port for WireGuard. Click `Add Ingress Rules`. (MAKE SURE YOU LEAVE THE `Source Port Range` BLANK, OTHERWISE TRAFFIC WILL BE BLOCKED)

(By default there should be a rule under `Egress` that allows all traffic to leave your instance. If this rule is not present you will need to add it. Click add Egress Rule. Destination CIDR should be `0.0.0.0/0`, IP Protocol should be `All Protocols`, and leave the port range blank. Click `Add Egress Rule`.)

## Connecting to Your Instance

Before you begin this step make sure you have installed (Putty)[https://www.putty.org/], or whatever SSH client you prefer, and have your private key somewhere accessible.

### Converting Your Key (PuTTY Only)

Assuming you are using PuTTY, you will need to first convert your key to a `.ppk` from the `.key` that you downloaded when creating your instance.

1. Open `PuTTYgen`, click `Conversions` from the top bar, and select `Import key`.
2. Navigate to the `.key` file you downloaded, select it, and click `Open`.
3. Click `Save private key`, and save the new `.ppk` file somewhere safe.

### Connecting

1. Open `PuTTY`, and in the `Host Name` field enter `opc@<your reserved public IP>`, replacing `<your reserved public IP>` with the reserved public IP you obtained earlier in Oracle. It should look something like `opc@123.456.789.012`
2. Leave the port as `22`, or set it to `22` if it isn't already, and make sure the connection type is set to `SSH` on `Telnet`.
3. On the left hand side, navigate to `Connection > SSH > Auth > Credentials`, and click `Browse` under `Private key file for authentication`. Select the `.ppk` file you created in the previous step.
4. Go back to the `Session` tab, then under `Saved Sessions` enter a name for the connection, and click `Save`.
5. Click `Open` to connect to your instance. You may get a security warning about the server's host key, click `Accept` to continue. You should now be connected to your instance via SSH.

(To connect in the future, open PuTTY, select the session you saved, and click `Load`, then `Open` to connect.)

## Setting Up the OUTSIDE Tunnel

Because the Oracle instance has a public IP assigned to it, it will be serving as your "outside" server. This means that the public IP assigned to your instance will effectively be your new public IP, and all traffic will be sent to it first.

### Install Script

1. Once you are connected to your instance via SSH, run the following commands to download and run the install script for the outside server:

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Skribb11es/oracle-udp-tunnel-setup/refs/heads/master/install_scripts/udp-reverse-tunnel-outside.sh)"
```

2. Follow the prompts from the script, you will be asked for the port you configured earlier, and an optional secret key for authentication (I personally recommend using one, as someone could spoof your inside server and intercept any traffic that is sent to your outside server without it). 

3. Once the script is finished, your outside server should be set up and running. You can check the status of the service with the following command:

```bash
sudo systemctl status udp-tunnel-outside
```

As long as you see something similar to what is below, then your outside server is set up and ready to go.

```sh
systemd[1]: Started reverse UDP tunnel (outside agent).
udp-tunnel[758037]: UDP tunnel outside agent v1.3 
udp-tunnel[758037]: listening on port 51820
```

## Setting Up the INSIDE Tunnel

The inside server is the machine that you want to send traffic to. This can be any machine that has an internet connection. Ideally this machine is being used as a router of some sort, either for a VPN instance that you have setup, or just a standalone machine for ingres of traffic.

### Install Script
1. On the machine you want to use as your inside server, run the following command to download and run the install script for the inside server:

#### Debian/Ubuntu
```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Skribb11es/oracle-udp-tunnel-setup/refs/heads/master/install_scripts/debian-udp-reverse-tunnel-inside.sh)"
```

#### RHEL/CentOS/Fedora
```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Skribb11es/oracle-udp-tunnel-setup/refs/heads/master/install_scripts/rhel-udp-reverse-tunnel-inside.sh)"
```

2. Like before, fill out the prompts with the appropriate information. This time you will need to provide the local service you are looking to tunnel, eg `localhost:51820` for a WireGuard instance running on the same machine, and the public IP and port of your outside server in Oracle, eg `123.456.789.012:51820`. You will also be prompted for the same optional secret key that you set on the outside server, make sure to enter the same key if you set one.

3. Once the script is finished, validate that the service started successfully by running the following command:

```bash
sudo systemctl status udp-tunnel-inside
```

4. If the service is running, you should see something similar to the following:

```sh
udp-tunnel[4142]: UDP tunnel inside agent v1.3
udp-tunnel[4142]: building tunnels to outside agent at 123.456.789.012, port 51820
udp-tunnel[4142]: forwarding incomimg UDP to test, port 51820
udp-tunnel[4142]: creating initial outgoing tunnel
```

5. At this point go back to your PuTTY session, and run the following command to validate that the outside server is receiving the tunnel connection from the inside server:

```bash
systemctl status udp-tunnel-outside
```

You should see something like the following. This means that the outside server is receiving the connection from the inside server, and that it has made a tunnel for it, but that there is no active sessions for the tunnel yet. When you send traffic to the outside server, the active sessions should increase, and it will again make a new tunnel for the next incoming connection.

```sh
udp-tunnel[776296]: new incoming reverse tunnel from: YOUR_PUBLIC_IP:RANDOM_PORT
udp-tunnel[776296]: Total: 1, active: 0, spare: 1
```

Seeing the above in your remote client does in fact mean that you have successfully set up the tunnel! Now whatever service you were planning to connect to through the tunnel can be done via setting the hostname to the IP of your outside server, and the port that you configured. Effectively, treat the public IP of your Oracle instance as your new public IP, and any traffic that you want sent to your inside server should be sent to the Oracle IP, and it will handle it from there.

## Conclusion

An important note about this tunnel, you will need to make a new tunnel per UDP port that you want to forward. You can make multiple outside services on the same Oracle instance, but you will need to configure them by manually making a new unique service file for each one, and changing the ports etc accordingly. The install script works as a good example of what you need to do to set up a new service, and where everything is located.

Also note, performance through the tunnel is highly dependant on the amount of hops that your traffic will need to go through. Given that you are likely trying to avoid a double NAT situation, there is a good chance that your traffic will go through 4-5 hops at least, which will add latency. You are still more than able to access any local web interfaces, ssh clients, or anything else that you have setup on your inside server, but services such as video streaming or gaming that require low latency may not perform well through the tunnel.