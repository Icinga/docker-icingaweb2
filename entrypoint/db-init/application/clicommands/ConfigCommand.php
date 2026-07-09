<?php
// Icinga Web 2 Docker image | (c) 2024 Icinga GmbH | GPLv2+

namespace Icinga\Module\Dockerentrypoint\Clicommands;

use Icinga\Application\Config;
use Icinga\Cli\Command;
use Icinga\Util\Json;

class ConfigCommand extends Command
{
    public function renderAction(): void
    {
        echo Config::fromArray(Json::decode(file_get_contents('php://stdin'), true));
    }
}
