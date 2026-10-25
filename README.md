# Network Packet Log Analytics & Visualization

A data analytics mini-project exploring network packet logs with Excel, Python, MySQL, and Power BI. The project documents a workflow for validating traffic records, analyzing protocol and data-transfer patterns, and presenting results in an interactive dashboard.

## Project goals

- Inspect and clean a 10,000-record network packet log dataset.
- Validate data quality and analyze traffic with SQL.
- Visualize protocol distribution, session metrics, and destination traffic in Power BI.
- Summarize the workflow and findings in the project report.
## Dashboard

<img width="1013" height="565" alt="image" src="https://github.com/user-attachments/assets/544cea1c-fdda-431b-ace9-cc999d37e389" />


## Dataset

[`Dataset/network_packet_logs.xlsx`](Dataset/network_packet_logs.xlsx) contains 10,000 records and these ten fields:

| Field | Description |
| --- | --- |
| `timestamp` | Time associated with the packet-log record |
| `src_ip` / `dst_ip` | Source and destination IP addresses |
| `src_port` / `dst_port` | Source and destination ports |
| `protocol` | Network protocol: TCP, UDP, or ICMP |
| `packet_count` | Number of packets in the session |
| `total_bytes` | Total bytes transferred |
| `duration_seconds` | Session duration in seconds |
| `bytes_per_second` | Transfer rate in bytes per second |

## Workflow

1. **Excel and Python EDA** — inspect the workbook, check for missing or duplicate records, and review protocol counts. The report documents a Python EDA step using Pandas and Matplotlib; its script is not included in this repository.
2. **MySQL** — use the queries in [`SQL/network_packet_logs_analysis.sql`](SQL/network_packet_logs_analysis.sql) to set up the table and validate and analyze the data.
3. **Power BI** — open [`powerbi/Network_packetlog_visualization.pbix`](powerbi/Network_packetlog_visualization.pbix) to explore the report's protocol, session, destination, and time-range visualizations.

## Key findings

- The report records 10,000 rows and no missing values across the ten fields.
- Protocol counts are nearly balanced: ICMP 3,353; TCP 3,343; UDP 3,304.
- The largest reported session transfer is 32,589 bytes.
- Transfer rates and packet counts vary across sessions.
- The documented dashboard includes protocol distribution, session-level metrics, destination rankings, and a timestamp filter.

## Project files

- [`Dataset/`](Dataset/) — Excel dataset.
- [`SQL/`](SQL/) — MySQL setup, validation, and analysis queries.
- [`powerbi/`](powerbi/) — Power BI report.
- [`Reports/Network_Packet_Log_Analytics_Documentation.docx`](Reports/Network_Packet_Log_Analytics_Documentation.docx) — project documentation, workflow, and findings.
- [`Reports/Network_Analytics_Presentation.pptx`](Reports/Network_Analytics_Presentation.pptx) — project presentation.

For the full methodology, visualizations, and future enhancement ideas, see the documentation in `Reports/`.
