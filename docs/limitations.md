# Known limitations

1. When migrating/updating ***semantic models published in Power BI Service***:
    - The Power BI workspace must use Premium Capacity, Premium Per User, Embedded, or Fabric Capacity. Pro is not supported.
    - XMLA read-write must be enabled for Premium Capacity or Embedded.
2. When migrating/updating ***local files***:
    - Local files are supported only when using [Power BI Project](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-overview) (.pbip) file format and [TMDL-format](https://powerbi.microsoft.com/en-us/blog/tmdl-in-power-bi-desktop-developer-mode-preview/) for semantic models. 
        - Power BI Desktop → File → Options and Settings → Options → Preview features → Power BI Project (.pbip) save option.
        - Power BI Desktop → File → Options and Settings → Options → Preview features → Store semantic model using TMDL format.
        ![Power BI Desktop settings](/images/powerbi-desktop-settings.png)