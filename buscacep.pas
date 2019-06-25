unit buscacep;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DBXJSON,
  DBXJSONReflect, idHTTP, IdSSLOpenSSL, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Data.DB, Datasnap.DBClient, Vcl.Grids, Vcl.DBGrids, Vcl.DBCtrls, Vcl.Mask,
  Vcl.Buttons, IdSMTP, IdMessage, IdText, IdAttachmentFile, IdUserPassProvider,
  IdSASLLogin, IdEMailAddress, IdExplicitTLSClientServerBase, REST.Response.Adapter,
  System.JSON;


type
  TTipoConsulta = (tcCep, tcEndereco);

type
  TEnderecoCompleto = record
    CEP,
    logradouro,
    complemento,
    bairro,
    localidade,
    uf,
    unidade,
    IBGE : string
  end;

type
  TFrmBuscaCep = class(TForm)
    Panel2: TPanel;
    bt_close: TButton;
    Panel1: TPanel;
    Label2: TLabel;
    Label3: TLabel;
    EdtLogradouro: TDBEdit;
    Label6: TLabel;
    EdtComplemento: TDBEdit;
    Label7: TLabel;
    EdtBairro: TDBEdit;
    Label8: TLabel;
    EdtLocalidade: TDBEdit;
    Label9: TLabel;
    EdtUF: TDBEdit;
    Label11: TLabel;
    EdtCep: TDBEdit;
    Label14: TLabel;
    Memo_json: TMemo;
    DBGrid1: TDBGrid;
    ds_dados: TDataSource;
    cds_dados: TClientDataSet;
    cds_dadosLogradouro: TStringField;
    cds_dadosCEP: TStringField;
    cds_dadosComplemento: TStringField;
    cds_dadosUF: TStringField;
    cds_dadosBairro: TStringField;
    cds_dadosIBGE: TStringField;
    cds_dadosUnidade: TStringField;
    cds_dadosLocalidade: TStringField;
    Label10: TLabel;
    EdtPais: TDBEdit;
    Label12: TLabel;
    EdtNumero: TDBEdit;
    cds_dadosNumero: TIntegerField;
    cds_dadosNome: TStringField;
    cds_dadosIdentidade: TStringField;
    cds_dadosCpf: TStringField;
    cds_dadosTelefone: TStringField;
    cds_dadosEmail: TStringField;
    Label4: TLabel;
    edtNome: TDBEdit;
    Label5: TLabel;
    edtIdentidade: TDBEdit;
    Label13: TLabel;
    EdtCpf: TDBEdit;
    Label15: TLabel;
    EdtTelefone: TDBEdit;
    Label16: TLabel;
    EdtEmail: TDBEdit;
    bt_salvar: TSpeedButton;
    bt_cancelar: TSpeedButton;
    bt_cadastrar: TSpeedButton;
    bt_modificar: TSpeedButton;
    bt_excluir: TSpeedButton;
    SaveDialog1: TSaveDialog;
    cds_dadosPais: TStringField;
    procedure bt_closeClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure EdtCepExit(Sender: TObject);
    procedure bt_cadastrarClick(Sender: TObject);
    procedure bt_cancelarClick(Sender: TObject);
    procedure bt_modificarClick(Sender: TObject);
    procedure bt_salvarClick(Sender: TObject);
    procedure bt_excluirClick(Sender: TObject);
    procedure ds_dadosStateChange(Sender: TObject);
    procedure EdtUFKeyPress(Sender: TObject; var Key: Char);
    procedure EdtCpfKeyPress(Sender: TObject; var Key: Char);
    procedure EdtTelefoneKeyPress(Sender: TObject; var Key: Char);
    procedure EdtNumeroKeyPress(Sender: TObject; var Key: Char);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

  private
    { Private declarations }

    // vari·veis e objetos necess·rios para o envio
    IdSSLIOHandlerSocket: TIdSSLIOHandlerSocketOpenSSL;
    IdSMTP: TIdSMTP;
    IdMessage: TIdMessage;
    IdText: TIdText;
    sAnexo: string;

    function getDados(params: TEnderecoCompleto; tipoConsulta: TTipoConsulta): TJSONObject;
    function removerAcentuacao(str: string): string;
    procedure CarregaDados(JSON: TJSONObject);
    procedure CarregaDadosEndereco(jsonArray: TJSONArray);
    procedure LimparCampos;
    procedure numericopuro(var Key: Char);
    procedure mensagemAviso(mensagem: string);
    procedure HabilitarCamposTela(Habilita:Boolean);
    function EnviaEmail(Assunto, Mensagem, ListaEmailsDestino: AnsiString): Boolean;

    var
      dadosEnderecoCompleto : TEnderecoCompleto;

  public
    { Public declarations }
  end;

var
  FrmBuscaCep: TFrmBuscaCep;

implementation

{$R *.dfm}

{ TForm1 }



procedure TFrmBuscaCep.bt_cadastrarClick(Sender: TObject);
begin
  try
      HabilitarCamposTela(true);
    ds_dados.DataSet.Insert;
  except
  end;
end;

procedure TFrmBuscaCep.bt_cancelarClick(Sender: TObject);
begin
  try
    if ds_dados.DataSet.Active and (ds_dados.DataSet.State in [dsEdit, dsInsert]) then
    begin
      ds_dados.DataSet.Cancel;
      HabilitarCamposTela(false);
    end;
  except
  end;
end;

procedure TFrmBuscaCep.bt_modificarClick(Sender: TObject);
begin
  try
    HabilitarCamposTela(true);
    ds_dados.DataSet.Edit;
  except
  end;
end;

procedure TFrmBuscaCep.bt_salvarClick(Sender: TObject);
var ZeroValue : Integer;
    Assunto, Titulo, email : string;
begin

  if edtNome.Text = '' then
  begin
    ShowMessage('Favor informar o nome ');
    exit;
  end;


  try
    ds_dados.DataSet.Post;
    HabilitarCamposTela(false);
  except
  end;

  if not cds_dados.IsEmpty then
  begin
    cds_dados.SaveToFile(ExtractFilePath(Application.ExeName)+edtNome.Text+'-'+EdtCpf.Text+'.xml', dfXML);
    sAnexo := ExtractFilePath(Application.ExeName)+edtNome.Text+'-'+EdtCpf.Text+'.xml';

    ShowMessage('Arquivo foi exportado para o diretorio :'+sAnexo);

    ShowMessage('Para o envio do email, dever· configurar os dados para envio na funÁ„o EnviaEmail');


// funÁ„o EnviaEmail, dever· ser configurado os dados de smtp, porta, email e usuario e senha para envio do email.
//  if EnviaEmail(Assunto, Titulo, email) then
//  begin
//    if ParamCount = ZeroValue then
//      ShowMessage('NotificaÁ„o enviada com sucesso para ' + email);
//  end
//  else
//    ShowMessage('Falha realizar notificaÁ„o');
  end;
end;

procedure TFrmBuscaCep.bt_excluirClick(Sender: TObject);
begin
  if (ds_dados.DataSet.IsEmpty) then
    Exit;

  try
    ds_dados.DataSet.Delete;
    bt_modificar.Enabled := ds_dados.DataSet.RecordCount > 0;
    bt_excluir.Enabled := ds_dados.DataSet.RecordCount > 0;

    HabilitarCamposTela(false);

  except

  end;
end;

procedure TFrmBuscaCep.bt_closeClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TFrmBuscaCep.CarregaDados(JSON: TJSONObject);
begin
  try
    cds_dadosLogradouro.AsString  := JSON.Get('logradouro').JsonValue.Value;
    cds_dadosCEP.AsString         := JSON.Get('cep').JsonValue.Value;
    cds_dadosLocalidade.AsString  := UpperCase(JSON.Get('localidade').JsonValue.Value);
    cds_dadosBairro.AsString      := JSON.Get('bairro').JsonValue.Value;
    cds_dadosUF.AsString          := JSON.Get('uf').JsonValue.Value;
    cds_dadosComplemento.AsString := JSON.Get('complemento').JsonValue.Value;
    cds_dadosIBGE.AsString        := JSON.Get('ibge').JsonValue.Value;
    cds_dadosUnidade.AsString     := JSON.Get('unidade').JsonValue.Value;
    cds_dadosPais.AsString        := 'Brasil';
  except
    on e: Exception do
    begin
      Application.MessageBox(PChar('Ocorreu um erro ao consultar o CEP'), 'Erro', MB_OK + MB_ICONERROR);
    end;
  end;
end;

procedure TFrmBuscaCep.CarregaDadosEndereco(jsonArray: TJSONArray);
var
  i : Integer;
  resultados, jsonObjeto : TJSONObject;
begin
  cds_dados.DisableControls;

  try
    for i := 0 to jsonArray.Size - 1 do
    begin
      cds_dados.Append;
      cds_dadosLogradouro.AsString  := TJSONObject(jsonArray.Get(i)).Get('logradouro').JsonValue.Value;
      cds_dadosCEP.AsString         := TJSONObject(jsonArray.Get(i)).Get('cep').JsonValue.Value;
      cds_dadosLocalidade.AsString  := UpperCase(TJSONObject(jsonArray.Get(0)).Get('localidade').JsonValue.Value);
      cds_dadosBairro.AsString      := TJSONObject(jsonArray.Get(i)).Get('bairro').JsonValue.Value;
      cds_dadosUF.AsString          := TJSONObject(jsonArray.Get(i)).Get('uf').JsonValue.Value;
      cds_dadosComplemento.AsString := TJSONObject(jsonArray.Get(i)).Get('complemento').JsonValue.Value;
      cds_dadosIBGE.AsString        := TJSONObject(jsonArray.Get(i)).Get('ibge').JsonValue.Value;
      cds_dadosUnidade.AsString     := TJSONObject(jsonArray.Get(i)).Get('unidade').JsonValue.Value;
      cds_dadosPais.AsString        := 'Brasil';
      cds_dados.Post;
    end;
  finally
    cds_dados.First;
    cds_dados.EnableControls;
  end;

end;

procedure TFrmBuscaCep.ds_dadosStateChange(Sender: TObject);
begin
   bt_cadastrar.Enabled := (Sender as TDataSource).State in [dsBrowse];
   bt_salvar.Enabled := (Sender as TDataSource).State in [dsEdit, dsInsert];
   bt_cancelar.Enabled := bt_salvar.Enabled;
   bt_modificar.Enabled := (bt_cadastrar.Enabled) and not ((Sender as TDataSource).DataSet.IsEmpty);
   bt_excluir.Enabled := bt_modificar.Enabled;
end;

procedure TFrmBuscaCep.HabilitarCamposTela(Habilita: Boolean);
var
   x, intContador: integer;

begin
  for x := 0 to Self.ComponentCount - 1 do
  begin
  if Components[x] is TCustomEdit then (Components[x] as TCustomEdit).Enabled := Habilita
     else if Components[x] is TComboBox then (Components[x] as TComboBox).Enabled := Habilita
     else if Components[x] is TDBLooKupComboBox then (Components[x] as TDBLooKupComboBox).Enabled := Habilita
     else if Components[x] is TCheckBox then (Components[x] as TCheckBox).Enabled := Habilita
     else if Components[x] is TRadioGroup then (Components[x] as TRadioGroup).Enabled := Habilita
     else if Components[x] is TDBEdit then (Components[x] as TRadioGroup).Enabled := Habilita
     else if Components[x] is TMaskEdit then (Components[x] as TMaskEdit).Enabled := Habilita;
  end;

end;

procedure TFrmBuscaCep.EdtCepExit(Sender: TObject);
var
  jsonObject: TJSONObject;
begin
  LimparCampos;

  if Length(EdtCep.Text) <> 8 then
  begin
    mensagemAviso('CEP inv·lido');
    EdtCep.SetFocus;
    exit;
  end;

  dadosEnderecoCompleto.CEP := EdtCep.text;

  jsonObject := getDados(dadosEnderecoCompleto, tcCep);

  if jsonObject <> nil then
    CarregaDados(jsonObject)
  else
  begin
    mensagemAviso('CEP inv·lido ou n„o encontrado');
    EdtCep.SetFocus;
    Exit;
  end;
end;

procedure TFrmBuscaCep.EdtCpfKeyPress(Sender: TObject; var Key: Char);
begin
  if not CharInSet(Key, ['0' .. '9', #8, #13, #27, ^C, ^V, ^X, ^Z]) then
  begin
    Key := #0;
  end;
end;

procedure TFrmBuscaCep.EdtNumeroKeyPress(Sender: TObject; var Key: Char);
begin
  if not CharInSet(Key, ['0' .. '9', #8, #13, #27, ^C, ^V, ^X, ^Z]) then
  begin
    Key := #0;
  end;
end;

procedure TFrmBuscaCep.EdtTelefoneKeyPress(Sender: TObject; var Key: Char);
begin
  if not CharInSet(Key, ['0' .. '9', #8, #13, #27, ^C, ^V, ^X, ^Z]) then
  begin
    Key := #0;
  end;
end;

procedure TFrmBuscaCep.EdtUFKeyPress(Sender: TObject; var Key: Char);
begin
  if not CharInSet(Key, ['0' .. '9', #8, #13, #27, ^C, ^V, ^X, ^Z]) then
  begin
    Key := #0;
  end;
end;
procedure TFrmBuscaCep.FormCreate(Sender: TObject);
begin
  Memo_json.Text := '';

  cds_dados.Close;
  cds_dados.CreateDataSet;

  HabilitarCamposTela(false);
end;

procedure TFrmBuscaCep.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
     perform(WM_NEXTDLGCTL,0,0);
end;

function TFrmBuscaCep.getDados(params: TEnderecoCompleto; tipoConsulta: TTipoConsulta): TJSONObject;
var
  HTTP: TIdHTTP;
  IDSSLHandler: TIdSSLIOHandlerSocketOpenSSL;
  Response: TStringStream;
  JsonArray: TJSONArray;
begin
  try
    HTTP := TIdHTTP.Create;
    IDSSLHandler := TIdSSLIOHandlerSocketOpenSSL.Create;
    HTTP.IOHandler := IDSSLHandler;
    Response := TStringStream.Create('');

    if tipoConsulta = tcCep then
    begin
      HTTP.Get('https://viacep.com.br/ws/' + params.CEP + '/json', Response);
      if (HTTP.ResponseCode = 200) and not (UTF8ToString(Response.DataString) = '{'#$A'  "erro": true'#$A'}') then
      begin
        Memo_json.Text := UTF8ToString(Response.DataString);
        Result := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(UTF8ToString(Response.DataString)), 0) as TJSONObject;
      end
      else
        raise Exception.Create('CEP inexistente!');
    end;

    if tipoConsulta = tcEndereco then
    begin
      HTTP.Get('https://viacep.com.br/ws/' + params.uf + '/' + removerAcentuacao(params.localidade) + '/' + removerAcentuacao(params.logradouro) + '/json', Response);
      if (HTTP.ResponseCode = 200) and not (UTF8ToString(Response.DataString) = '{'#$A'  "erro": true'#$A'}') then
      begin
        JsonArray := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(UTF8ToString(Response.DataString)), 0) as TJSONArray;
        memo_json.Text := UTF8ToString(Response.DataString);
        CarregaDadosEndereco(JsonArray);
        Result := TJSONObject(JsonArray);
      end
      else
        raise Exception.Create('EndereÁo inexistente ou n„o encontrado!');
    end;

  finally
    FreeAndNil(HTTP);
    FreeAndNil(IDSSLHandler);
    Response.Destroy;
  end;
end;

procedure TFrmBuscaCep.LimparCampos;
var
  I : integer;
begin
  for I := 0 to Self.ControlCount - 1 do
    if Self.Controls[I] is TEdit then
      TEdit(Self.Controls[I]).Clear;

  memo_json.Clear;

  dadosEnderecoCompleto.CEP := '';
  dadosEnderecoCompleto.logradouro := '';
  dadosEnderecoCompleto.complemento := '';
  dadosEnderecoCompleto.uf := '';
  dadosEnderecoCompleto.bairro := '';
  dadosEnderecoCompleto.IBGE := '';
  dadosEnderecoCompleto.unidade := '';
  dadosEnderecoCompleto.localidade := '';

  with cds_dados do
  begin
    DisableControls;
    try
      while not Eof do
        Delete;
    finally
      EnableControls;
    end;
  end;
end;

procedure TFrmBuscaCep.mensagemAviso(mensagem: string);
begin
  Application.MessageBox(PChar(mensagem), '', MB_OK + MB_ICONERROR);
end;

procedure TFrmBuscaCep.numericopuro(var Key: Char);
begin
  if not CharInSet(Key, ['0' .. '9', #8, #13, #27, ^C, ^V, ^X, ^Z]) then
  begin
    Key := #0;
  end;
end;

function TFrmBuscaCep.removerAcentuacao(str: string): string;
var
  x: Integer;
const
  ComAcento = '‡‚ÍÙ˚„ı·ÈÌÛ˙Á¸¿¬ ‘€√’¡…Õ”⁄«‹';
  SemAcento = 'aaeouaoaeioucuAAEOUAOAEIOUCU';
begin
  for x := 1 to Length(Str) do

    if Pos(Str[x], ComAcento) <> 0 then
      Str[x] := SemAcento[Pos(Str[x], ComAcento)];

  Result := Str;
end;

function TFrmBuscaCep.EnviaEmail(Assunto, Mensagem,
  ListaEmailsDestino: AnsiString): Boolean;
var
  IdMessage: TIdMessage;
  IdUserPassProvider: TIdUserPassProvider;
  IdSASLLogin: TIdSASLLogin;
  IdSMTP: TIdSMTP;
  i: Integer;
  Anexo: string;
  EmailRemetente, NomeRemetente, HostSMTP, Usuario, Senha, ListaAnexos: string;
  ListaEmailsCopia, ListaEmailsCopiaOculta: string;
  RequerAutenticacao: Boolean;

  function RetornaCampo(Linha, Separador: string; OrdemCampo: Integer): string;
  var
    i, Posicao: Integer;
  begin
    Result := '';
    Linha := Separador + Linha + Separador;
    for i := 1 to OrdemCampo do
    begin
      Posicao := Pos(Separador, Linha);
      Linha := Copy(Linha, Posicao + Length(Separador), Length(Linha));
    end;
    Posicao := Pos(Separador, Linha);
    Result := Copy(Linha, 1, Posicao - 1);
  end;

  procedure PreencheListaEmails(Lista: TIdEmailAddressList; Enderecos: string);
  var
    i: Integer;
    Email: string;
  begin
    i := 1;
    Email := RetornaCampo(Enderecos, ',', i);
    while Email <> '' do
    begin
      Lista.Add;
      Lista.Items[i - 1].Address := Email;
      Inc(i);
      Email := RetornaCampo(Enderecos, ',', i);
    end;
  end;

begin
  IdMessage := TIdMessage.Create(nil);
  IdSMTP := TIdSMTP.Create(nil);

  EmailRemetente := ''; // endereco do remetente
  NomeRemetente := ''; // Nome Remtente
  HostSMTP := ''; // SMTP, endereÁo do servidor
  RequerAutenticacao := True;
  Usuario := ''; // usuario a ser logado na conta para envio do email
  Senha := ''; // senha do usuario
  ListaAnexos := '';
  ListaEmailsCopia := '';
  ListaEmailsCopiaOculta := '';

  IdMessage.Subject := Assunto;
  IdMessage.From.Address := EmailRemetente;
  IdMessage.From.Name := NomeRemetente;
  ListaEmailsDestino := StringReplace(ListaEmailsDestino, ';', ',', [rfReplaceAll]);
  PreencheListaEmails(IdMessage.Recipients, ListaEmailsDestino);
  PreencheListaEmails(IdMessage.CCList, ListaEmailsCopia);
  PreencheListaEmails(IdMessage.BccList, ListaEmailsCopiaOculta);

  IdMessage.Body.Text := Mensagem;
  IdSMTP.Host := HostSMTP;
  IdSMTP.Port := 0; // porta do smtp
  if RequerAutenticacao then
  begin
    IdUserPassProvider := TIdUserPassProvider.Create(IdSMTP);
    IdUserPassProvider.Username := Usuario;
    IdUserPassProvider.Password := Senha;

    IdSASLLogin := TIdSASLLogin.Create(IdSMTP);
    IdSASLLogin.UserPassProvider := IdUserPassProvider;

    IdSMTP.AuthType := satSASL;
    with IdSMTP.SASLMechanisms.Add do
      SASL := IdSASLLogin;
  end;

  i := 1;
  Anexo := RetornaCampo(ListaAnexos, ',', i);
  while Anexo <> '' do
  begin
    TIdAttachmentFile.Create(IdMessage.MessageParts, TFileName(Anexo));
    Inc(i);
    Anexo := RetornaCampo(ListaAnexos, ',', i);
  end;

  IdSMTP.Connect;
  IdSMTP.Send(IdMessage);
  IdSMTP.Disconnect;

  Result := True;
  IdMessage.Free;
  IdSMTP.Free;

end;


end.
