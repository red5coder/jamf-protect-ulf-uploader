# Jamf Protect Unified Logging Filter Uploader

The "Jamf Protect Unified Logging Filter Uploader" is a macOS app that allows you to batch upload Unified Logging Filters from the [Jamf Protect Repo](https://github.com/jamf/jamfprotect/tree/main/unified_log_filters) to a Jamf Protect tenant.

### Requirements

- A Mac running macOS Venture (13.0) or higher
- A Jamf Protect Tenant
- A Jamf Protect API client needs to be created with the following permissions. 
  - Read and Write for Unified Logging

### Usage
The app will require the credentials to access your Jamf Protect Tenant. This includes:
  - Your Jamf Protect URL
  - The Client ID for the API Client you created
  - The password for the API client you created
  
Click the "Fetch Filters" button, this will retrieve the available filters.

Select the ones you wish to upload by selecting the checkbox by each one.

Click Upload

The app does log to Unified Logging. You can view the logs like this:

`log stream --predicate 'subsystem == "uk.co.mallion.jamf-protect-ulf-uploader"' --level info`

<img width="1027" alt="mainscreen" src="https://github.com/red5coder/jamf-protect-ulf-uploader/assets/29920386/dc8dfdee-1492-41e6-9899-6d85fe186110">


