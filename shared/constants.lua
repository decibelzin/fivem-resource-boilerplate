--- Nomes de evento e enums transversais. Enum de um módulo só vive em shared/config/<modulo>.lua.
--- Eventos levam o nome do resource como prefixo: renomear a pasta não exige caçar strings.
--- Evento novo: `<NOME> = ('%s:<modulo>:<acao>'):format(RESOURCE)`, com direção e audiência no comentário.
RESOURCE = GetCurrentResourceName()

EVENT = {
    --- server → server (outros resources): resource pronto (schema aplicado, online re-bindados).
    READY = ('%s:ready'):format(RESOURCE),
}
