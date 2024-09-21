# Customer / Members

## Video Tutorial

**We created a video tutorial demonstrating these steps.** You can find the [video here](https://youtu.be/QxltZ1I6lGk) in our [YouTube channel](https://www.youtube.com/channel/UCeW2fmMTBtE4fnlmg-2-evA). As always, [the full catalog of video tutorials is here](https://www.ixpmanager.org/support/tutorials).


## Adding Customers

To add a new customer in **IXP Manager**, select the *Customers* option from the left hand side admin menu and then click the `[+]` icon on the top right. You'll find yourself with a form such as (may vary over time):

![Adding a Customer](img/customer-add.png)

What follows is an explanation of each section.

## Customer Details

The `Name` field is the customer's name as you/they typically want it to appear in IXP Manager. It is not necessarily their full legal entity name (that goes elsewhere). The `Abbreviated Name` is a shorter version of the name that is used in space constrained areas such as graph labels.

The `Type` field is a dropdown with the following meanings:

* `Full`: this is what you will use most of the time. This is a full / normal trafficking IXP member.
* `Pro-bono`: like full but for organisations that you provide IXP access to *for the good of the internet / your members*. Examples at INEX include the [AS112 service](../features/as112.md), [Packet Clearing House's](https://www.pch.net/) route collector and DNS TLD/root services and other DNS root servers such as the RIPE K root / Verisign, etc.
* `Internal`: while not enforced, you should really only have two internal customers which is the IXP itself and, separately, the IXP route servers. Connections / interfaces such as route collectors and core links would be associated with the IXP customer. Because route servers typically have a dedicated ASN, they would have their own customer with their interfaces associated here.
* `Associate`: INEX has a concept of *associate members* which enables those organisations who are involved in the IP and networking industry, but who do not have their own IP traffic to peer, an opportunity to participate in the extensive INEX community. See [full details here](https://www.inex.ie/become-a-member/associate-membership/). Associate customers in IXP Manager have very limited functionality but it allows us to keep track of them.

The `Shortname` field is something we are slowly removing. It is currently visible in some URLs and a couple other areas. It should be a lowercase single word (`[a-z0-9]`) and it should not be changed after it is set.

The `Corporate Website` is used when linking the customer name in various customer lists. It must be a valid URL. Try and stick to the scheme: `http://www.example.com/` - i.e. include `http[s]://` and end with a trailing slash.

The `Date Joined` is just that and must be set. However, the `Date Left` has real consequences: **setting `Date Left` effectively closes the customer's account**. This means configuration will no longer be included for graphing, router configuration, etc. We tend not to delete customers but mark them as closed by setting this field.

`Status` yields three options. The most important of which is `Normal` which is what you'll use nearly 100% of the time. Setting either of the other two options (`Suspended` / `Not Connected`) will have the same effect as closing the account as described above: removing route server / collector sessions, graphing configuration, etc.

`MD5 Support`: this is not something that has been fully integrated into all view screens. You should probably default to `Yes` for now as this will cover 95+% of cases. It is an informational flag only for member to member bilateral peering.

### Peering Details

The `AS Number` is just the integer value without any `AS` prefix, etc.

`Max Prefixes` is known as the *global max prefixes value*. It is used to work out the appropriate max prefixes value to apply to all router configurations in the stock / default templates (route collector and servers, AS112). The calculated value is also included in emails from the *Peering Manager* from customer to customer.

There are two issues with max prefixes:

* it is also possible to set a max prefixes value on a per VLAN interface basis. This is not ideal and something we intend to fix.
* the same value is used for IPv4 and IPv6 which is also something that needs to be fixed.

The max prefixes value is worked out in the code when generating router configuration is as follows:

1. the greater of the *global* value as above or the VLAN interface value.
2. if neither is set, a default of 250 is used.

At INEX, we default to 50 for small members, and 250 for medium sized members (who may already have 50 say), and as advised by larger members.

The `Peering Email` is used in member lists and by the *Peering Manager* for sending emails. We try and encourage an alias of `peering@example.com` but this does not always work out.

The `IPv4 Peering Macro` is used instead of the AS number when set to generate inbound prefix filters for the route servers based on the member's published IRR records. `AS-BTIRE` in the RIPE database is an example for BT Ireland.

The `IPv6 Peering Macro` was added for another IX using IXP Manager that had a customer which used a separate macro for v4 and v6. We only know of that single instance of this. In the event that `IPv6 Peering Macro` is set, this will be used to generate IPv6 inbound prefix filters, otherwise the `IPv4 Peering Macro` will be used for both. If neither is set, the IRR policy of the AS number will be used. Use `AS-NULL` to disable one or the other protocol peering macro if only one is required.

It is not possible to have a different ASN for IPv4 and IPv6. We are not aware of any cases where this should be necessary but if it is, create two customers.

The `Peering Policy` is informational only and is displayed in member lists. Typically speaking, route server members should have an open peering policy but others are possible if you use standard route server communities for controlling the distribution of prefixes.

The IRRDB source sets the database where IXP Manager queries the customer's IRR data from. See [the IRRDB feature page](../features/irrdb.md) for more information.

The checkbox labelled `Active Peering Matrix` indicates whether or not the customer's route server and bilateral peering sessions should appear in the public peering matrix.

### NOC Details

All of this is purely informational and is used by IX staff to contact the member about various issues. It is also available to other customers of the exchange to similarly contact their bilateral peers with any issues.

### Reseller Details

This section will only be displayed if reseller functionality is enabled.

See the [reseller instructions](../features/reseller.md) for details on this.

## Welcome Emails

When a new customer is provisioned, you can send them a *welcome email* from IXP Manager which is a useful way to provide all their connectivity details and other on-boarding information for your IX.

From the *Customer Overview* page, you will find the *Send Welcome Email...* option under the tools menu on the top right hand corner of the page:

![Welcome Email](img/customer-welcome-email.png)

To be useful, you need to [skin](../features/skinning.md) the welcome email.

Its format is Markdown and it is sent as a HTML email. The file you need to skin is (with an example of how to do it):

```
cd ${IXPROOT}
mkdir -p resources/skins/example/customer/emails
cp resources/views/customer/emails/welcome-email.blade.php resources/skins/inex/customer/emails/
```

The `example` skin name in the above *is just an example*. Please read the [skinning documentation](../features/skinning.md).


## Customer Logos

Customer users and administrators can upload and manage logos for customers. To enable this functionality, set the following in your `${IXPROOT}/.env` file:

```
IXP_FE_FRONTEND_DISABLED_LOGO=false
```

When you do this, the ability to manage logos will appear:

* under the *Edit* menu (top right, pencil icon) for administrators on the *Customer Overview* page;
* via a *Your Logo* section on the customer user's landing page after logging in.

Logos will then be shown in the customer overview page and a new admin left-hand-side menu option called *Member Logos* (which shows all logos).

Logos are stored under `${IXPROOT}/public/logos` in a sharded directory structure based on the SHA1 of the image content.


## Customer Name Display

Following a [feature request](https://github.com/inex/IXP-Manager/issues/88), we have a configuration option which can be set to allow each IXP Manager installation customise how the customer / member name is displayed. E.g. *Acme Ltd* or *Acme Ltd (AS65500)* for example.

You can customise this by setting the following option in your `.env`:

```
IXP_FE_CUSTOMER_NAME_FORMAT=""%a (AS%i)"
```

The above is the default which uses the abbreviated name and the customer's ASN. You can see the available options in the [`config/ixp_fe.php` file](https://github.com/inex/IXP-Manager/blob/master/config/ixp_fe.php).

You can also find more detail in this [issue thread](https://github.com/inex/IXP-Manager/issues/766). 

## Registration and Billing Details

After you add a new customer (or from the customer overview page from the dropdown edit icon on the right of the title area, you can select *Edit Billing/Registration Details*), you will get the following form:

![Customer Registration and Billing Details](img/customer-reg-billing.png)

All of these details are informative only and only available to administrative users.

### Notification of Billing Details Changed

If you want notification of a customer's billing details being changed by email, set the following parameter in your `${IXPROOT}/.env` file:

```
IXP_FE_CUSTOMER_BILLING_UPDATES_NOTIFY="mail@example.com"
```

This can be useful to alert your accounts / billing staff of these changes automatically.

If you need multiple people notified, use an alias address encompassing all the users.

## Public Customer Details

**IXP Manager** makes customer/member details available publicly (without login) through the *Member Information* menu item. To disable this, set the following in your `.env`:

```
IXP_FE_CUSTOMER_DETAILS_PUBLIC=false
```
