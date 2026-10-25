-- ============================================================
--  NAAN MUDHALVAN PROJECT — NETWORK PACKET LOG ANALYSIS
--  Database  : sibi
--  Table     : network_packet_logs
--  Dataset   : 10,000 rows × 10 columns
--  Author    : Sibi Manikandan V
-- ============================================================

-- ============================================================
-- SECTION 0 : DATABASE & TABLE SETUP
-- ============================================================

CREATE DATABASE IF NOT EXISTS sibi;
USE sibi;

DROP TABLE IF EXISTS network_packet_logs;

CREATE TABLE network_packet_logs (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    timestamp         DATETIME,
    src_ip            VARCHAR(20),
    dst_ip            VARCHAR(20),
    src_port          INT,
    dst_port          INT,
    protocol          VARCHAR(10),   -- TCP | UDP | ICMP
    packet_count      INT,
    total_bytes       BIGINT,
    duration_seconds  DECIMAL(12,6),
    bytes_per_second  DECIMAL(15,4)
);

-- After importing the CSV/Excel data, verify:
SELECT COUNT(*) AS total_rows FROM network_packet_logs;
-- Expected: 10000


-- ============================================================
-- SECTION 1 : VALIDATION QUERIES
-- ============================================================

-- ── 1.1  Check for NULL values in every column ───────────────
SELECT
    SUM(CASE WHEN timestamp        IS NULL THEN 1 ELSE 0 END) AS null_timestamp,
    SUM(CASE WHEN src_ip           IS NULL THEN 1 ELSE 0 END) AS null_src_ip,
    SUM(CASE WHEN dst_ip           IS NULL THEN 1 ELSE 0 END) AS null_dst_ip,
    SUM(CASE WHEN src_port         IS NULL THEN 1 ELSE 0 END) AS null_src_port,
    SUM(CASE WHEN dst_port         IS NULL THEN 1 ELSE 0 END) AS null_dst_port,
    SUM(CASE WHEN protocol         IS NULL THEN 1 ELSE 0 END) AS null_protocol,
    SUM(CASE WHEN packet_count     IS NULL THEN 1 ELSE 0 END) AS null_packet_count,
    SUM(CASE WHEN total_bytes      IS NULL THEN 1 ELSE 0 END) AS null_total_bytes,
    SUM(CASE WHEN duration_seconds IS NULL THEN 1 ELSE 0 END) AS null_duration,
    SUM(CASE WHEN bytes_per_second IS NULL THEN 1 ELSE 0 END) AS null_bps
FROM network_packet_logs;

-- ── 1.2  Check for duplicate rows ────────────────────────────
SELECT
    timestamp, src_ip, dst_ip, src_port, dst_port, protocol,
    COUNT(*) AS duplicate_count
FROM network_packet_logs
GROUP BY timestamp, src_ip, dst_ip, src_port, dst_port, protocol
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- ── 1.3  Validate allowed protocols (should be TCP, UDP, ICMP only) ──
SELECT protocol, COUNT(*) AS count
FROM network_packet_logs
GROUP BY protocol;

-- Flag any unexpected protocol values
SELECT *
FROM network_packet_logs
WHERE protocol NOT IN ('TCP', 'UDP', 'ICMP');

-- ── 1.4  Validate port numbers (must be 1–65535) ─────────────
SELECT *
FROM network_packet_logs
WHERE src_port < 1 OR src_port > 65535
   OR dst_port < 1 OR dst_port > 65535;

-- ── 1.5  Validate numeric columns — no negative or zero values ──
SELECT *
FROM network_packet_logs
WHERE packet_count     <= 0
   OR total_bytes      <= 0
   OR duration_seconds <= 0
   OR bytes_per_second <= 0;

-- ── 1.6  Validate IP address format (basic format check) ─────
SELECT src_ip, COUNT(*) AS occurrences
FROM network_packet_logs
WHERE src_ip NOT REGEXP
    '^([0-9]{1,3}\\.){3}[0-9]{1,3}$'
GROUP BY src_ip;

SELECT dst_ip, COUNT(*) AS occurrences
FROM network_packet_logs
WHERE dst_ip NOT REGEXP
    '^([0-9]{1,3}\\.){3}[0-9]{1,3}$'
GROUP BY dst_ip;

-- ── 1.7  Sanity check: bytes_per_second ≈ total_bytes / duration ──
--         Tolerance: allow 1% variance
SELECT id, src_ip, dst_ip, total_bytes, duration_seconds,
       bytes_per_second,
       ROUND(total_bytes / duration_seconds, 4) AS calculated_bps,
       ABS(bytes_per_second - (total_bytes / duration_seconds)) AS diff
FROM network_packet_logs
WHERE ABS(bytes_per_second - (total_bytes / duration_seconds))
      > (bytes_per_second * 0.01)
LIMIT 20;

-- ── 1.8  Validate destination ports match known service ports ──
SELECT dst_port, COUNT(*) AS packet_count
FROM network_packet_logs
GROUP BY dst_port
ORDER BY dst_port;

-- Flag any unexpected destination ports
SELECT *
FROM network_packet_logs
WHERE dst_port NOT IN (21, 22, 25, 53, 80, 443, 8080);

-- ── 1.9  Check for ICMP packets using ports (ICMP should ignore ports) ──
SELECT *
FROM network_packet_logs
WHERE protocol = 'ICMP'
  AND (src_port IS NOT NULL OR dst_port IS NOT NULL)
LIMIT 10;

-- ── 1.10 Dataset completeness summary ────────────────────────
SELECT
    COUNT(*)                                        AS total_records,
    COUNT(DISTINCT src_ip)                          AS unique_src_ips,
    COUNT(DISTINCT dst_ip)                          AS unique_dst_ips,
    COUNT(DISTINCT protocol)                        AS protocols,
    MIN(timestamp)                                  AS earliest_packet,
    MAX(timestamp)                                  AS latest_packet,
    TIMESTAMPDIFF(SECOND, MIN(timestamp),
                           MAX(timestamp))          AS capture_duration_sec
FROM network_packet_logs;


-- ============================================================
-- SECTION 2 : ANALYSIS QUERIES
-- ============================================================

-- ── 2.1  Protocol distribution ───────────────────────────────
SELECT
    protocol,
    COUNT(*)                                        AS packet_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM network_packet_logs), 2) AS percentage
FROM network_packet_logs
GROUP BY protocol
ORDER BY packet_count DESC;

-- ── 2.2  Traffic volume by protocol ──────────────────────────
SELECT
    protocol,
    SUM(total_bytes)                                AS total_bytes_transferred,
    ROUND(AVG(total_bytes), 2)                      AS avg_bytes_per_packet,
    MAX(total_bytes)                                AS max_bytes,
    MIN(total_bytes)                                AS min_bytes
FROM network_packet_logs
GROUP BY protocol
ORDER BY total_bytes_transferred DESC;

-- ── 2.3  Top 10 source IPs by total traffic volume ───────────
SELECT
    src_ip,
    COUNT(*)                                        AS packet_count,
    SUM(total_bytes)                                AS total_bytes,
    ROUND(AVG(bytes_per_second), 2)                 AS avg_bps
FROM network_packet_logs
GROUP BY src_ip
ORDER BY total_bytes DESC
LIMIT 10;

-- ── 2.4  Top 10 destination IPs by traffic received ──────────
SELECT
    dst_ip,
    COUNT(*)                                        AS packet_count,
    SUM(total_bytes)                                AS total_bytes,
    ROUND(AVG(bytes_per_second), 2)                 AS avg_bps
FROM network_packet_logs
GROUP BY dst_ip
ORDER BY total_bytes DESC
LIMIT 10;

-- ── 2.5  Traffic by destination port (service breakdown) ─────
SELECT
    dst_port,
    CASE dst_port
        WHEN 21   THEN 'FTP'
        WHEN 22   THEN 'SSH'
        WHEN 25   THEN 'SMTP'
        WHEN 53   THEN 'DNS'
        WHEN 80   THEN 'HTTP'
        WHEN 443  THEN 'HTTPS'
        WHEN 8080 THEN 'HTTP-Alt'
        ELSE 'Unknown'
    END                                             AS service,
    COUNT(*)                                        AS packet_count,
    SUM(total_bytes)                                AS total_bytes,
    ROUND(COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM network_packet_logs), 2) AS pct_of_total
FROM network_packet_logs
GROUP BY dst_port
ORDER BY packet_count DESC;

-- ── 2.6  High-traffic flows (potential large transfers / anomalies) ──
--         Packets with bytes_per_second in top 1%
SELECT *
FROM network_packet_logs
WHERE bytes_per_second > (
    SELECT PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY bytes_per_second)
    -- If your MySQL version doesn't support PERCENTILE_CONT, use:
    -- SELECT bytes_per_second FROM network_packet_logs
    -- ORDER BY bytes_per_second DESC LIMIT 1 OFFSET 99
    FROM network_packet_logs
)
ORDER BY bytes_per_second DESC
LIMIT 20;

-- Alternative (MySQL 5.x / MariaDB compatible):
SELECT *
FROM network_packet_logs
ORDER BY bytes_per_second DESC
LIMIT 100;

-- ── 2.7  Average execution metrics per protocol ──────────────
SELECT
    protocol,
    ROUND(AVG(packet_count), 2)                     AS avg_packet_count,
    ROUND(AVG(total_bytes), 2)                      AS avg_total_bytes,
    ROUND(AVG(duration_seconds), 4)                 AS avg_duration_sec,
    ROUND(AVG(bytes_per_second), 2)                 AS avg_bps,
    ROUND(MAX(bytes_per_second), 2)                 AS peak_bps
FROM network_packet_logs
GROUP BY protocol;

-- ── 2.8  Hourly traffic trend ────────────────────────────────
SELECT
    DATE_FORMAT(timestamp, '%Y-%m-%d %H:00:00')     AS hour_window,
    COUNT(*)                                        AS packets,
    SUM(total_bytes)                                AS bytes_transferred,
    ROUND(AVG(bytes_per_second), 2)                 AS avg_bps
FROM network_packet_logs
GROUP BY hour_window
ORDER BY hour_window;

-- ── 2.9  Protocol × port cross-analysis ──────────────────────
SELECT
    protocol,
    dst_port,
    CASE dst_port
        WHEN 21 THEN 'FTP' WHEN 22 THEN 'SSH' WHEN 25 THEN 'SMTP'
        WHEN 53 THEN 'DNS' WHEN 80 THEN 'HTTP' WHEN 443 THEN 'HTTPS'
        WHEN 8080 THEN 'HTTP-Alt' ELSE 'Other'
    END                                             AS service,
    COUNT(*)                                        AS packet_count,
    SUM(total_bytes)                                AS total_bytes
FROM network_packet_logs
GROUP BY protocol, dst_port
ORDER BY protocol, packet_count DESC;

-- ── 2.10 Suspicious traffic: unusually high bytes_per_second ─
--         Flag connections with bps > 100,000 (potential data exfil)
SELECT
    timestamp, src_ip, dst_ip, dst_port, protocol,
    total_bytes, duration_seconds,
    ROUND(bytes_per_second, 2)                      AS bps,
    'HIGH BPS ALERT'                                AS flag
FROM network_packet_logs
WHERE bytes_per_second > 100000
ORDER BY bytes_per_second DESC;

-- ── 2.11 Suspicious traffic: very short duration but large bytes ──
SELECT
    timestamp, src_ip, dst_ip, protocol,
    total_bytes, ROUND(duration_seconds, 6) AS duration_sec,
    ROUND(bytes_per_second, 2)              AS bps
FROM network_packet_logs
WHERE duration_seconds < 0.1
  AND total_bytes > 5000
ORDER BY bytes_per_second DESC
LIMIT 20;

-- ── 2.12 Most frequent src_ip → dst_ip communication pairs ───
SELECT
    src_ip,
    dst_ip,
    protocol,
    COUNT(*)                                        AS connection_count,
    SUM(total_bytes)                                AS total_bytes
FROM network_packet_logs
GROUP BY src_ip, dst_ip, protocol
ORDER BY connection_count DESC
LIMIT 15;

-- ── 2.13 Packet count distribution (small vs large sessions) ─
SELECT
    CASE
        WHEN packet_count BETWEEN 1  AND 5  THEN '1–5 packets'
        WHEN packet_count BETWEEN 6  AND 10 THEN '6–10 packets'
        WHEN packet_count BETWEEN 11 AND 15 THEN '11–15 packets'
        WHEN packet_count BETWEEN 16 AND 20 THEN '16–20 packets'
        ELSE '20+ packets'
    END                                             AS packet_range,
    COUNT(*)                                        AS session_count,
    ROUND(COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM network_packet_logs), 2) AS percentage
FROM network_packet_logs
GROUP BY packet_range
ORDER BY MIN(packet_count);

-- ── 2.14 DNS traffic analysis (port 53) ──────────────────────
SELECT
    protocol,
    COUNT(*)                                        AS dns_packets,
    SUM(total_bytes)                                AS total_bytes,
    ROUND(AVG(duration_seconds), 4)                 AS avg_duration
FROM network_packet_logs
WHERE dst_port = 53
GROUP BY protocol;

-- ── 2.15 HTTPS vs HTTP traffic comparison ────────────────────
SELECT
    dst_port,
    CASE dst_port WHEN 80 THEN 'HTTP' WHEN 443 THEN 'HTTPS' END AS service,
    protocol,
    COUNT(*)                                        AS packets,
    SUM(total_bytes)                                AS total_bytes,
    ROUND(AVG(bytes_per_second), 2)                 AS avg_bps
FROM network_packet_logs
WHERE dst_port IN (80, 443)
GROUP BY dst_port, protocol
ORDER BY dst_port, protocol;

-- ── 2.16 Overall summary statistics ──────────────────────────
SELECT
    COUNT(*)                                        AS total_sessions,
    SUM(total_bytes)                                AS total_bytes_all,
    ROUND(SUM(total_bytes) / 1048576, 2)            AS total_MB,
    ROUND(AVG(total_bytes), 2)                      AS avg_bytes_per_session,
    MAX(total_bytes)                                AS max_session_bytes,
    MIN(total_bytes)                                AS min_session_bytes,
    ROUND(AVG(bytes_per_second), 2)                 AS avg_bps_overall,
    MAX(bytes_per_second)                           AS peak_bps,
    ROUND(AVG(duration_seconds), 4)                 AS avg_duration_sec,
    ROUND(AVG(packet_count), 2)                     AS avg_packet_count
FROM network_packet_logs;

-- ============================================================
-- END OF FILE
-- ============================================================
