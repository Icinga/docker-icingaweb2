<?php

// Icinga Web 2 Docker image | (c) 2026 Icinga GmbH | GPLv2+

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

    public function parseAction(): void
    {
        echo json_encode(
            Config::fromIni($this->params->getRequired('file'))->toArray(),
            JSON_FORCE_OBJECT | JSON_THROW_ON_ERROR
        );
    }
}
