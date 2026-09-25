<?php
// Database configuration with Code Engine environment variable fallback
$sSERVERNAME = getenv('DB_SERVER_NAME') ?: '780791cb-554f-4c04-9152-d5eebcb72ea2.c7dvrhud08vgdqo60090.databases.appdomain.cloud';
$dbPort      = getenv('DB_SERVER_PORT') ?: '31264';
$sUSER      = getenv('DB_USER')        ?: '7617a448a40b54b0b522acb021577e55';
$sPASSWORD  = getenv('DB_PASSWORD')    ?: 'oeR9WzP7oGb0FSF5ldv2GTbyz0rIamh4';
$sDATABASE  = getenv('DB_NAME')        ?: 'ibmclouddb';

$sRootPath = '';
$bLockURL  = false;
$URL[0]    = 'https://churchcrm-providence.2f37fd9c0csn.us-south.codeengine.appdomain.cloud/';

require_once(dirname(__FILE__) . DIRECTORY_SEPARATOR . 'LoadConfigs.php');