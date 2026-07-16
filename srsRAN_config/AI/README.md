AI test configs for OCUDU / srsUE reference-clock debugging.

These files are copies derived from the current `gNB/docker_OtA.yml` and
`UE/ocudu_OtA_example.conf` with conservative changes intended for detach and
timing testing.

Goals:
- keep the original configs untouched
- make `clock` and `sync` explicit on the gNB side
- avoid the likely-misconfigured UE `time_source=gpsdo` case unless GPSDO is really present
- reduce debug/PCAP overhead during stability testing
- provide a starting `time_alignment_calibration` for external-reference RA testing

Files:
- `gNB_internal.yml`
- `gNB_external_10mhz_only.yml`
- `gNB_external_10mhz_pps.yml`
- `ue_internal.conf`
- `ue_external_10mhz_only.conf`
- `ue_external_10mhz_pps.conf`

Recommended test order:
1. `gNB_internal.yml` + `ue_internal.conf`
2. `gNB_external_10mhz_only.yml` + `ue_external_10mhz_only.conf`
3. `gNB_external_10mhz_pps.yml` + `ue_external_10mhz_pps.conf`

If external-reference tests still fail during random access, try adjusting:
- `ru_sdr.time_alignment_calibration`: `-100`, `-170`, `-250`

If underflows still dominate, keep testing with:
- `log.all_level: info`
- PCAP disabled
- `expert_execution.threads.lower_phy.execution_profile: dual`
