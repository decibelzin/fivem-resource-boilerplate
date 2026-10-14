--- Nomes de evento e enums transversais. Enum de um módulo só vive em shared/config/<modulo>.lua.
--- Eventos levam o nome do resource como prefixo: renomear a pasta não exige caçar strings.
RESOURCE = GetCurrentResourceName()

EVENT = {
    --- server → server (outros resources): resource pronto (schema aplicado, online re-bindados).
    READY = ('%s:ready'):format(RESOURCE),

    --- server → client (unicast, só staff): report novo. Payload = ReportPayload.
    REPORT_CREATED = ('%s:reports:created'):format(RESOURCE),

    --- server → client (unicast, só o autor): report fechado. Payload = ReportPayload.
    REPORT_CLOSED = ('%s:reports:closed'):format(RESOURCE),
}
