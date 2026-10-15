# Webhook Alerts — iOS source

Este pacote inclui um projeto Xcode básico (`ios/WebhookAlerts.xcodeproj`) e workflow Codemagic.

## Build
1. Envie o conteúdo deste ZIP para a raiz do repositório Git.
2. No Codemagic, selecione esse repositório e o workflow `ios-workflow`.
3. Execute o build. O workflow gera um `.app` sem assinatura para validar a compilação.

## Atenção
- O build sem assinatura não gera um IPA instalável/publicável. Para distribuir no iPhone, configure assinatura Apple e exportação IPA no Codemagic.
- Em `ios/WebhookAlerts/APIService.swift`, substitua `https://SEU-WORKER.workers.dev` pela URL real do backend.
- O backend precisa ser implantado separadamente; este pacote não inclui backend pronto para produção.
- O código foi estruturado, mas não foi possível executar o Xcode neste ambiente. Se surgir erro no build, compartilhe o log.
