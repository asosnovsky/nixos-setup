def rocm-monitor [
	cacheFile: string = "/tmp/rocm-monitor.jsonl",
	timeout: duration = 1sec
] {
	if ($cacheFile | path exists) {
		rm $cacheFile
	}
	loop {
		clear
		rocm-smi --showmemuse --showuse --json | save --append $cacheFile
		tail -n1 $cacheFile | from json --objects | flatten | print
		sleep $timeout
	}
}
