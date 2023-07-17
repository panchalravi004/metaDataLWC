# Salesforce Object and Field Creator LWC Component

## Overview
This repository contains a Lightning Web Component (LWC) that allows users to create Salesforce objects and fields using a JSON file. The component provides an input box where users can upload a JSON file containing metadata for the objects and fields they want to create. Upon clicking the "Create" button, the component processes the JSON file and generates the corresponding objects or fields in the Salesforce org.

## Prerequisites
Before using this component, ensure that you have the following:

1. A Salesforce org with Lightning Experience enabled.
2. Access to the Salesforce setup area to create objects and fields.
3. Basic knowledge of Salesforce object and field metadata.

## Installation
To install and use this component, follow these steps:

1. Clone the repository to your local machine or download the source code as a ZIP file.
2. Deploy the LWC component to your Salesforce org using any suitable method, such as Salesforce CLI or the Salesforce Extensions for Visual Studio Code.
3. Grant appropriate access to the component to the desired user profiles in your org.
4. Make sure that the necessary permissions are enabled for the user profiles to create objects and fields.

## Usage
1. Create a JSON file that contains the metadata for the objects and fields you want to create. The JSON file should follow the required format. Below is an example of a JSON file:

```json
[
    {
        "OBJECT_API":"Meta_Student__c",
        "OBJECT_LABEL":"Meta Student",
        "OBJECT_PURAL":"Meta Students",
        "FIELD_TYPE":"Text",
        "FIELD_LABEL":"Name",
        "DEPLOY_STATUS":"Deployed",
        "SHARING_MODEL":"ReadWrite",
        "Fields":[
          {
            "API":"First_Name__c",
            "LABEL":"First Name",
            "LENGTH":20,
            "TYPE":"Text"
          },
          {
            "API":"MetaLookup__c",
            "LABEL":"MetaLookup",
            "TYPE":"Lookup",
            "RELATION_LABEL":"MetaLookup",
            "RELATION_NAME":"MetaLookup",
            "REFERENCE_TO":"College__c"
          },
          {
            "API":"MetaMasterLookup__c",
            "LABEL":"MetaMasterLookup",
            "TYPE":"MasterDetail",
            "RELATION_LABEL":"MetaMasterLookup",
            "RELATION_NAME":"MetaMasterLookup",
            "REFERENCE_TO":"College__c",
            "WRITE_REQUIRES":false
          }
        ]
  }
]
```

2. In your Salesforce org, navigate to a Lightning page or component where you want to use the Object and Field Creator component.
3. Add the Object and Field Creator LWC component to the desired location on the page or component.
4. In the component properties or configuration, set any required attributes such as visibility, layout, or behavior.
5. Run the Lightning page or component. You will see the Object and Field Creator component with an input box for uploading the JSON file and a "Create" button.
6. Click on the "Choose File" button and select the JSON file you created earlier.
7. Click on the "Create" button to initiate the creation of objects and fields in your Salesforce org.
8. Wait for the component to process the JSON file. Upon completion, you will receive a success message indicating that the objects and fields were created successfully.

## Field Types
The following field types are supported by the component:

- Text
- Email
- Number
- Currency
- Percent
- Date
- Phone
- Lookup
- Master-Detail

## Future Enhancements
The following enhancements are planned for future releases:

- [ ] Support for creating picklist fields without specifying the picklist values in the JSON file.
- [ ] Field-level security permission settings for the created fields.
- [x] Ability to define page layouts for the created objects.

## Limitations
- The component currently supports creating custom objects and fields only. Standard Salesforce objects and fields are not supported.
- The component does not handle complex field types or relationships.
- It is recommended to thoroughly review the JSON file and ensure the accuracy of the metadata before uploading and creating objects and fields.

## Contributions
Contributions to this repository are welcome. If you encounter any issues or have suggestions for improvements, please feel free to submit a pull request or create an issue.

## Acknowledgments
- This project was inspired by the need for a simplified way to create multiple Salesforce objects and fields using a JSON file.
- Special thanks to the open-source community for providing valuable resources and libraries that facilitated the development of this component.

## Disclaimer
This component is provided as-is without any warranty. The author and contributors are not responsible for any damages or data loss that may occur while using this component. Use it at your own risk.
