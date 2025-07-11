#!/usr/bin/env php
<?php

function isFfmpegInstalled(): bool {
	$ffmpegCheck = shell_exec( 'ffmpeg -version 2>&1' );
	if ( ! str_contains( $ffmpegCheck, 'ffmpeg version' ) ) {
		return false;
	}

	return true;
}

function isVideoValid( $file ): bool {
	$probeCommand = "ffprobe -v error -show_format " . escapeshellarg( $file ) . " 2>&1";
	$probeOutput  = shell_exec( $probeCommand );

	if ( $probeOutput === null || ! str_contains( $probeOutput, 'duration=' ) ) {
		return false;
	}

	return true;
}

function getVideoDuration( $file ): float {
	$duration = shell_exec("ffprobe -select_streams v:0 -show_entries stream=duration -of csv=p=0 \"$file\"");
	return floatval(trim($duration));
}

function getOptions(): array {
	$opt = getopt( "hi:o:c:r:yn", [
		'help',
		'input:',
		'output:',
		'rows:',
		'cols:',
		'yes',
		'no',
	] );

	$options['input']  = $opt['input'] ?? $opt['i'] ?? false;
	$options['output'] = $opt['output'] ?? $opt['o'] ?? false;
	$options['rows'] = $opt['format'] ?? $opt['r'] ?? 4;
	$options['cols'] = $opt['format'] ?? $opt['c'] ?? 5;


	$options['yes'] = '';
	if ( isset( $opt['y'] ) ) {
		$options['yes'] = '-y';
	}
	if ( isset( $opt['yes'] ) ) {
		$options['yes'] = '-y';
	}

	if ( isset( $opt['n'] ) ) {
		$options['yes'] = '-n';
	}
	if ( isset( $opt['no'] ) ) {
		$options['yes'] = '-n';
	}

	$options['help'] = false;
	if ( isset( $opt['help'] ) ) {
		$options['help'] = true;
	}
	if ( isset( $opt['h'] ) ) {
		$options['help'] = true;
	}

	if ( ! $options['input'] ) {
		exit( 'Не указан input ' );
	}

	if ( ! $options['output'] ) {
		exit( 'Не указан output ' );
	}

	$options['input']  = realpath( $options['input'] );
	$options['output'] = realpath( $options['output'] );

	return $options;
}

$options = getOptions();





$input = "input.mp4";
$output = "storyboard.jpg";
$grid = 10;

$cols = 5;
$rows = 4;

$duration = getVideoDuration($input);

$frame_interval = $duration / ($cols * $rows);
$command = "ffmpeg -i '{$input}' -vf 'fps=1/{$frame_interval},scale=iw/{$cols}:ih/{$rows},tile={$cols}x{$rows}' -fps_mode vfr '{$output}' -y";

print_r( $command);

shell_exec($command);




//#!/usr/bin/env php
//<?php
//$input = "input.mp4";
//$output = "storyboard.jpg";
//$grid = 10;
//
//$duration = getVideoDuration($input);
//
//$frame_interval = $duration / ($grid * $grid);
//$command = sprintf(
//	'ffmpeg -i "%s" -vf "fps=1/%.2f,scale=iw/%d:ih/%d,tile=%dx%d" -fps_mode vfr "%s"',
//	$input,
//	$frame_interval,
//	$grid,
//	$grid,
//	$grid,
//	$grid,
//	$output
//);
//
//shell_exec($command);
//
//echo "Storyboard created: $output\n";