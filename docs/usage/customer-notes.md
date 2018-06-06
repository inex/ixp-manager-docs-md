# Customer Notes

**IXP Manager** allows administrators to add notes to customer records via the customer overview page.

Some of the features currently supported include:

* all actions are via AJAX allowing a quick seamless experience;
* notes can be private (visible to administrators only) or public (also visible to the customer via their own portal login);
* if a note is marked as public, there is a clear and obvious user interface hint to remind the admin of this;
* notes have a title *(required)* and a text area with markdown support for additional information;
* admins can choose to be alerted by email to new / edited / deleted notes in one of four ways:
    * never
    * all notes for all customers
    * watched customers only
    * watched notes only
* there is a *Unread Notes* action via the *My Account* menu to show a given admin a list of customers with unread notes for the administrator logged in.


## Notes in Customer Overview

The following image shows the standard customer overview page (as per v4.8.0) with the *Notes* tab selected and two sample notes:

![Customer Notes Overview](img/customer-notes-overview.png)

The first note, *Sample Private Note*, is a note that is only visible to administrators. The second note, *Test Public Note*, is visible to any user logged in for this customer.

The next image shows the dialog for adding a customer note.

![Customer Notes Add](img/customer-notes-add.png)

By default, notes are private and you are required to check the *Makee note visible to customer* to make it a public note.

The *Preview* table allows you to see what the note will look like when formatted via Markdown:

![Customer Notes Preview](img/customer-notes-preview.png)

Existing notes can be edited, deleted and viewed:

![Customer Notes View](img/customer-notes-view.png)



## Notifications

As mentioned above, administrators can choose to be alerted by email to new / edited / deleted notes in one of four ways:

1. never
2. all notes for all customers
3. watched customers only
4. watched notes only

On an administrator's *My Account -> Profile* page, you will find the following:

![Administrator Notification Preference for Notes](img/customer-notes-notifications.png)

The first of these radio options, *Disable all email notifications*, corresponds to *(1) never* above. The last of these radio options, *Email me on any change to any customer note* corresponds to *(2) all notes for all customers* above.

The middle option, *Email me on changes to only watched customers and notes*, is controlled via the *bell* icon on the customer overview notes tab. If a user had requested notifications as follows:

![Customer Notes Overview - Notifications](img/customer-notes-overview-notifications.png)


then all changes to any customer note for *AS112 Reverse DNS [AS112]* will be emailed to the user because the *customer bell* (the one on the top right) has been selected.

If the user had not selected the *customer bell* then:

* changes to *Sample Private Note* and any new notes added / edited / deleted would not be notified to the user.
* only changes to *Test Public Note* would be emailed to the user.

The order of precedence for determining if a note change should be notified by email is:

1. if the customer chose via their *Profile* the radio option *Disable all email notifications* then notifications are **never** sent.
2. if the customer chose via their *Profile* the radio option *Email me on any change to any customer note* then notifications are **always** sent.
3. If neither (1) nor (2) hold above, then the user has selected the radio option *Email me on changes to only watched customers and notes*. In which case a notification is sent for the customer whose note is being added / edited / deleted:

    a. if the *customer bell* is selected for the customer in question
    b. if the *note bell* is selected for the note in question

4. Otherwise no notification is sent.
