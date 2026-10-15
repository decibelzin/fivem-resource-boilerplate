--- Saída do cache: quem sai do servidor ou troca de personagem (a ponte avisa a troca). O próximo
--- `playerRegistry:get` resolve o personagem atual.
Framework.onCharacterChanged(function(src)
    playerRegistry:forget(src)
end)

AddEventHandler('playerDropped', function()
    playerRegistry:forget(source)
end)
