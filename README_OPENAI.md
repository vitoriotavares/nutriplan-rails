# Configuração da API OpenAI para o NutriPlan

## Configuração da Chave de API

Para utilizar a funcionalidade de geração de planos alimentares com IA, você precisa configurar sua chave de API da OpenAI:

1. Crie uma conta na [OpenAI](https://platform.openai.com/) se ainda não tiver
2. Obtenha sua chave de API no painel da OpenAI
3. Crie um arquivo `.env` na raiz do projeto com o seguinte conteúdo:

```
OPENAI_API_KEY=sua_chave_api_aqui
OPENAI_ORGANIZATION_ID=seu_id_organizacao_aqui  # Opcional
```

4. Reinicie o servidor Rails para que as variáveis de ambiente sejam carregadas

## Uso da Funcionalidade

A integração com a OpenAI é utilizada para gerar planos alimentares personalizados baseados nos dados da anamnese nutricional. O sistema:

1. Extrai informações relevantes da anamnese (dados de saúde, preferências, restrições, etc.)
2. Cria um prompt detalhado para a API da OpenAI
3. Processa a resposta e cria um plano alimentar personalizado

Se a API da OpenAI não estiver disponível ou ocorrer algum erro, o sistema utilizará o método de fallback para gerar um plano alimentar básico.

## Modelos Utilizados

O sistema está configurado para utilizar o modelo `gpt-4o` da OpenAI, que oferece o melhor equilíbrio entre qualidade e custo para a geração de planos alimentares personalizados.

## Custos

Lembre-se que o uso da API da OpenAI tem custos associados. Consulte a [página de preços](https://openai.com/pricing) para informações atualizadas sobre os custos de uso.
