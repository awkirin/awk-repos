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
	$opt = getopt( "hi:o:c:f:yn", [
		'help',
		'input:',
		'output:',
		'cmd:',
		'format:',
		'yes',
		'no',
	] );

	$options['input']  = $opt['input'] ?? $opt['i'] ?? false;
	$options['output'] = $opt['output'] ?? $opt['o'] ?? false;
	$options['cmd']    = $opt['cmd'] ?? $opt['c'] ?? '-crf 30';
	$options['format'] = $opt['format'] ?? $opt['f'] ?? 'mp4';


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



	// Валидация обязательных параметров
	$errors = [];
	if (empty($options['input'])) {
		$errors[] = 'Не указан input';
	}
	if (empty($options['output'])) {
		$errors[] = 'Не указан output';
	}

	if (!empty($errors)) {
		exit(implode(PHP_EOL, $errors));
	}





	$options['input']  = realpath( $options['input'] );
	$options['output'] = realpath( $options['output'] );

	return $options;
}

$options = getOptions();

if ( ! isFfmpegInstalled() ) {
	echo 'ffmpeg не установлен';
	exit( 0 );
}

if ( $options['help'] ) {
	exit( <<<EOF
Опции:
  -h, --help            Показать эту справку.
  -i, --input <путь>    Входная директория с видеофайлами.
  -o, --output <путь>   Выходная директория для сохранения файлов.
  -c, --cmd <значение>  Значение CRF для управления качеством.
  -f, --format <формат> Формат выходных файлов (например: mp4).

Пример:
  php script.php -i /src -o /dest -f mp4 -c 23
EOF);
}


$iteratorFiles = new RecursiveIteratorIterator(
	new RecursiveDirectoryIterator( $options['input'],
		FilesystemIterator::SKIP_DOTS
	)
);

$files = [];
foreach ( $iteratorFiles as $iteratorFile ) {
	if ( isVideoValid( $iteratorFile->getRealPath() ) ) {
		$files[] = $iteratorFile;
	}
}


/* @var SplFileInfo $file */
foreach ( $files as $file ) {

//	if ( ! isVideoValid( $file->getRealPath() ) ) {
//		continue;
//	}

	$fileExtension = $file->getExtension();
	$fileBasename  = $file->getBasename( '.' . $fileExtension );

	$relativePath = substr( $file->getPath(), strlen( $options['input'] ) + 1 );
	$outputDir    = $options['output'] . DIRECTORY_SEPARATOR . $relativePath;
	if ( ! is_dir( $outputDir ) ) {
		mkdir( $outputDir, 0777, true );
	}
	$outputFile = $outputDir . DIRECTORY_SEPARATOR . $fileBasename . '.' . $options['format'];

	$command = "ffmpeg -i '{$file->getRealPath()}' {$options['cmd']} {$options['yes']} '{$outputFile}'";
	$result  = shell_exec( $command );

	echo PHP_EOL . PHP_EOL;
}