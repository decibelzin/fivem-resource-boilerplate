--- Módulo de exemplo (canônico): reports de jogador para a staff.
--- Tudo que um humano pode querer ajustar vive aqui — nada de número ou texto mágico no service.
ReportsConfig = {
    --- ACE que libera listar/fechar reports e receber o aviso de report novo.
    --- server.cfg: `add_ace group.admin reports.manage allow`
    permission = 'reports.manage',

    commands = {
        create = 'report', -- client: /report <mensagem>
        list = 'reports', -- staff/console: /reports
        close = 'closereport', -- staff/console: /closereport <id>
    },

    minLength = 10,
    maxLength = 300,
    --- Intervalo mínimo entre reports do mesmo jogador (RAM — zera no restart do resource).
    cooldownSeconds = 120,
    maxOpenPerAuthor = 3,
    listLimit = 20,

    --- Texto mostrado ao jogador. Erros indexados pelo `code` devolvido pelo server.
    messages = {
        sent = 'Report #%s enviado — a staff foi avisada.',
        closed = 'Seu report #%s foi fechado pela staff.',
        staffNew = 'Report #%s de %s: %s',
        fallbackError = 'Não foi possível enviar o report (%s).',
        errors = {
            message_too_short = 'Descreva melhor o problema.',
            message_too_long = 'Mensagem longa demais.',
            cooldown = 'Aguarde um pouco antes de enviar outro report.',
            too_many_open = 'Você já tem reports abertos demais.',
            not_online = 'Você ainda não foi carregado no servidor.',
            not_ready = 'O servidor ainda está iniciando.',
            rpc_timeout = 'O servidor não respondeu. Tente de novo.',
        },
    },
}

REPORT_STATUS = {
    OPEN = 'open',
    CLOSED = 'closed',
}
