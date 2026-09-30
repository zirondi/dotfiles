# Segredos Criptografados (SOPS)

Para manter o seu ambiente seguro, os segredos (`tokens`, `senhas`) não devem ser comitados em texto plano.
O script de deploy foi atualizado para decriptar os segredos automaticamente na máquina de destino antes de subir o `podman-compose`.

## Como inicializar segredos

Você não precisa criar estes arquivos manualmente. Em vez disso, use o nosso script gerador:

```bash
# Na raiz do seu repositório dotfiles:
./scripts/init-secrets.sh <nome-do-servico>
```

Esse script vai varrer o `compose.yml` do seu serviço, descobrir todos os segredos que você apontou para `./secrets/XYZ`, e vai criar stubs (arquivos falsos) já criptografados na sua pasta.

## Como editar um segredo gerado

Após rodar o script acima, para preencher o segredo com o seu token/senha real, utilize o próprio sops:

```bash
sops services/<nome-do-servico>/secrets/<nome_do_segredo>.sops.yaml
```

Isso abrirá o arquivo no seu editor de texto. Cole o token, salve e feche.
Na hora que você rodar o `./deploy.sh`, o script se encarregará de transportar e decriptar!
