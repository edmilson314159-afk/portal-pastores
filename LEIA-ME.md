# Portal dos Pastores – Maranata

Arquivos:
- `index.html` – o portal inteiro
- `logo-maranata-branca.png` e `logo-maranata-azul.png` – logo com fundo transparente (usada no portal)
- `supabase.sql` – banco de dados e regras de acesso
- `manifest.webmanifest`, `icone-180.png`, `icone-192.png`, `icone-512.png` – permitem instalar o portal
  na tela inicial do celular, como um aplicativo

Sem configurar nada, o `index.html` abre em **modo demonstração**
(senha dos pastores: `maranata`; administrador: qualquer e-mail com a senha `admin`).

## Abas
Atas · Escala de Pregação · Manual do Membro · Informes · Aniversariantes · Agenda · Logos

- **Atas:** aceitam só PDF ou Word (.docx). Ao enviar, o portal lê o texto do documento
  e guarda para a busca. Fotos, PDFs digitalizados e o .doc antigo são recusados com aviso.
  A busca encontra o assunto no título, no resumo e no conteúdo da ata (ignora acentos)
  e mostra o trecho onde aparece.
- **Escala de Pregação:** só PDF, com o mês de referência. A escala do mês atual aparece em
  destaque, com Abrir e Baixar; as dos outros meses ficam listadas logo abaixo.
- **Manual do Membro:** só PDF. A versão mais recente aparece em destaque; as anteriores
  ficam guardadas em "Versões anteriores".

## Como funciona o acesso
- **Pastores:** digitam só a senha. Por trás, o portal entra numa conta única compartilhada.
- **Três administradores:** clicam em "Acesso administrativo" e entram com e-mail e senha próprios.
  Só eles veem os botões de adicionar e excluir.
- Os arquivos ficam num armazenamento privado: só quem entrou no portal consegue abri-los.

## Publicação (passo a passo)

1. **Supabase:** use o projeto que já hospeda os apps de batismo, frequência e Três Amigos.
   As tabelas do portal têm o prefixo `pastores_` e não se misturam com as dos outros apps.
2. **SQL Editor:** abra `supabase.sql`, troque no final os e-mails `admin1/2/3@exemplo.com`
   pelos e-mails reais dos três administradores e clique em **Run**.
   (O arquivo pode ser rodado de novo sem problema, por exemplo depois de uma atualização do portal.)
3. **Authentication > Users > Add user** (marque "Auto confirm user"):
   - `pastores@portalmaranata.app` com a **senha que os pastores vão usar**;
   - os três administradores, cada um com sua senha.
4. **Não desative** "Allow new users to sign up" neste projeto: o app de frequência depende
   do cadastro dos alunos. O portal continua protegido, porque só os e-mails da tabela
   `pastores_acessos` conseguem ver ou alterar o conteúdo.
5. **Chaves de conexão:** já estão preenchidas no topo do `index.html` (`CONFIG`).
   Para voltar ao modo demonstração, basta deixar `SUPABASE_URL` vazio.
6. **GitHub + Vercel:** suba todos os arquivos (menos este LEIA-ME e o supabase.sql) num repositório (ex.: `portal-pastores`)
   e importe no Vercel, como nos outros apps. Não precisa de configuração de build.

## Trocar a senha dos pastores
Supabase > Authentication > Users > `pastores@portalmaranata.app` > alterar senha.
Quem já estava conectado continua até clicar em "Sair"; para derrubar todos,
use também "Sign out user" nesse mesmo usuário.

## Instalar no celular como aplicativo
- **Android (Chrome):** abra o link do portal > menu ⋮ > **Adicionar à tela inicial** / **Instalar app**.
- **iPhone (Safari):** abra o link > botão Compartilhar > **Adicionar à Tela de Início**.
O portal passa a abrir em tela cheia, com o ícone da Maranata.
