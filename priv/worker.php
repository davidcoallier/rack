#!/usr/bin/env php
<?php

chdir($argv[0]);

file_put_contents(__DIR__ . '/php.log', stream_get_contents($argv));

function read_request()
{
    $stdin = fopen('php://stdin', 'r+');
    file_put_contents(__DIR__ . '/php.log', stream_get_contents($stdin));
}

function handle_request()
{
}

function load_app()
{
    $config = json_decode(file_get_contents('config.json'));
    $app    = ($config['phar_file']);
    $mtime  = filemtime('config.json');

    return ['app' => $app, 'last_mtime' => $mtime];
}

$app = false;
$last_mtime = false;

while (true) {
    $env = read_request();


    if (!$app || !$last_mtime) { 
        $app = load_app();
        $app = $app['app'];
        $last_mtime = $app['last_mtime'];
    }

    if (!$app || !$last_mtime || (isset($last_mtime) && 
        filemtime('config.json') > $last_mtime)) 
    {
        $app = load_app();
        $app = $app['app'];
        $last_mtime = $app['last_mtime'];
    }

    handle_request($app, $env);
}
