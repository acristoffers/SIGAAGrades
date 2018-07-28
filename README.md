# SIGAA:Notas

Aplicativo criado para automatizar a visualização de notas no site do SIGAA do CEFET/MG.

Ele funciona fazendo o mesmo que você faria: entrando no SIGAA e navegando curso por curso vendo as notas.
Ele não toma decisões caso haja, por exemplo, notícia que requer confirmação.
Neste caso ele retornará um erro ou agirá como se não houvesse curso cadastrado.
Você deve então entrar no SIGAA por um navegador e certificar-se que não há mais notícias, que a página inicial é exibida logo após o login.

Sua senha não é guardada em nehum servidor: fica no seu aparelho. A conexão com o SIGAA é criptografada.

O problema que ele tenta resolver é bem específico: a ausência de uma página que liste todas as notas das disciplinas do semestre atual.

Este problema é resolvido através de um Web Scraper, já que o SIGAA não fornece API pública.

***Este aplicativo não foi desenvolvido em parceria com o CEFET.
O CEFET não tem absolutamente nenhuma ligação com ele.***

# LICENSE

Copyright 2018 Álan Crístoffer

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
