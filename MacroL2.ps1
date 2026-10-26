$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
Add-Type -ReferencedAssemblies System.Windows.Forms -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
using System.Windows.Forms;
public class MacroWindow : Form {
 [DllImport("user32.dll")] public static extern bool RegisterHotKey(IntPtr h, int id, uint mods, uint key);
 [DllImport("user32.dll")] public static extern bool UnregisterHotKey(IntPtr h, int id);
 [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern int GetWindowText(IntPtr h, StringBuilder b, int n);
 [StructLayout(LayoutKind.Sequential)] struct INPUT {public uint type; public UNION u;}
 [StructLayout(LayoutKind.Explicit)] struct UNION {
  [FieldOffset(0)] public KEYBDINPUT ki;
  [FieldOffset(0)] public MOUSEINPUT mi;
 }
 [StructLayout(LayoutKind.Sequential)] struct KEYBDINPUT {public ushort vk, scan; public uint flags, time; public UIntPtr extra;}
 [StructLayout(LayoutKind.Sequential)] struct MOUSEINPUT {public int dx,dy; public uint data,flags,time; public UIntPtr extra;}
 [DllImport("user32.dll", SetLastError=true)] static extern uint SendInput(uint n, INPUT[] inputs, int size);
 public event Action ToggleRequested;
 public event Action StopRequested;
 protected override void WndProc(ref Message m) {
  if(m.Msg==0x312) {if(m.WParam.ToInt32()==1 && ToggleRequested!=null) ToggleRequested(); if(m.WParam.ToInt32()==2 && StopRequested!=null) StopRequested();}
  base.WndProc(ref m);
 }
 public static string ActiveTitle() {var b=new StringBuilder(1024);GetWindowText(GetForegroundWindow(),b,b.Capacity);return b.ToString();}
 public static bool Press(ushort key) {
  var a=new INPUT[2];a[0].type=1;a[0].u.ki.vk=key;a[1].type=1;a[1].u.ki.vk=key;a[1].u.ki.flags=2;
  uint sent=SendInput(2,a,Marshal.SizeOf(typeof(INPUT)));
  if(sent==1) SendInput(1,new[]{a[1]},Marshal.SizeOf(typeof(INPUT)));
  return sent==2;
 }
}
'@
$form = New-Object MacroWindow
$form.Text = 'Macro L2 — sequência de skills'
$form.ClientSize = New-Object System.Drawing.Size(600,620)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font('Segoe UI',10)
function Label($text,$x,$y,$w=550,$h=26) {
 $c=New-Object System.Windows.Forms.Label; $c.Text=$text; $c.SetBounds($x,$y,$w,$h);$form.Controls.Add($c)
}
function TextBox($text,$x,$y,$w,$h=28) {
 $c=New-Object System.Windows.Forms.TextBox;$c.Text=$text;$c.SetBounds($x,$y,$w,$h);$form.Controls.Add($c);return $c
}
Label 'Sequência de teclas' 24 18
Label 'Uma por linha: tecla, intervalo em milissegundos após a tecla.' 24 48
Label 'Exemplo: F1, 800   •   Aceita F1–F12, A–Z, 0–9 e NumPad0–9.' 24 75
$sequence=TextBox '' 24 108 550 180
$sequence.Multiline=$true;$sequence.ScrollBars='Vertical'
Label 'Texto que deve aparecer no título da janela do jogo:' 24 302
$title=TextBox '' 24 331 550
Label 'Atalho para ligar/desligar (clique no campo e pressione):' 24 374
$hotkey=TextBox '' 24 404 350
$hotkey.ReadOnly=$true
Label 'Escolha seu atalho para ligar e desligar a sequência.' 24 438
$button=New-Object System.Windows.Forms.Button;$button.Text='Ligar / desligar';$button.SetBounds(24,478,220,38);$form.Controls.Add($button)
$save=New-Object System.Windows.Forms.Button;$save.Text='Salvar configuração';$save.SetBounds(260,478,220,38);$form.Controls.Add($save)
$status=New-Object System.Windows.Forms.Label;$status.SetBounds(24,532,550,66);$status.Text='Desligado. Configure a sequência e o atalho.';$form.Controls.Add($status)
$script:running=$false;$script:steps=@();$script:index=0;$script:due=0L
$script:mods=0; $script:key=0
$config=Join-Path $PSScriptRoot 'config.json'
if(Test-Path -LiteralPath $config) {
 try {$c=Get-Content -LiteralPath $config -Raw | ConvertFrom-Json;$sequence.Text=[string]$c.sequence;$title.Text=[string]$c.title;$script:mods=[int]$c.mods;$script:key=[int]$c.key;$hotkey.Text=[string]$c.shortcut} catch {}
}
function Stop-Macro {$script:running=$false;$status.Text='Desligado.';$sequence.Enabled=$true;$title.Enabled=$true;$hotkey.Enabled=$true}
function Toggle-Macro {
 if($script:running){Stop-Macro;return}
 try {
  if([string]::IsNullOrWhiteSpace($title.Text)){throw 'Preencha um trecho do título da janela do jogo.'}
  $items=@()
  foreach($line in ($sequence.Text -split '\r?\n')) {
   if([string]::IsNullOrWhiteSpace($line)){continue}
   if($line -notmatch '^\s*(F(?:[1-9]|1[0-2])|[A-Z0-9]|NumPad[0-9])\s*,\s*(\d+)\s*$'){throw "Linha inválida: $line"}
   $name=$Matches[1];$delay=[int]$Matches[2]
   if($delay -lt 50 -or $delay -gt 600000){throw 'Os intervalos devem ficar entre 50 e 600000 ms.'}
   $vk=[int][Enum]::Parse([System.Windows.Forms.Keys],$(if($name -match '^\d$'){"D$name"}else{$name}),$true)
   $items+=@{key=$vk;delay=$delay}
  }
  if($items.Count -eq 0){throw 'Adicione pelo menos uma tecla.'}
  if($script:key -eq 0){throw 'Escolha um atalho para ligar e desligar.'}
  if(-not (Register-Toggle)){throw 'Atalho indisponível. Escolha outra combinação.'}
  $script:steps=$items;$script:index=0;$script:due=0L;$script:running=$true
  $sequence.Enabled=$false;$title.Enabled=$false;$hotkey.Enabled=$false
  $status.Text='Ativado. Aguardando a janela do jogo em primeiro plano.'
 }catch{[System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'Configuração inválida')|Out-Null}
}
function Register-Toggle {
 [MacroWindow]::UnregisterHotKey($form.Handle,1)|Out-Null
 if($script:key -eq 0){return $false}
 return [MacroWindow]::RegisterHotKey($form.Handle,1,[uint32]($script:mods -bor 0x4000),[uint32]$script:key)
}
$hotkey.Add_KeyDown({
 param($sender,$e)
 $e.SuppressKeyPress=$true
 if($e.KeyCode -in @('ControlKey','ShiftKey','Menu','LWin','RWin')){return}
 $oldMods=$script:mods;$oldKey=$script:key
 $script:mods=0;if($e.Control){$script:mods=$script:mods -bor 2};if($e.Alt){$script:mods=$script:mods -bor 1};if($e.Shift){$script:mods=$script:mods -bor 4}
 $script:key=[int]$e.KeyCode
 if(Register-Toggle){$hotkey.Text=$e.KeyData.ToString()}else{
  $script:mods=$oldMods;$script:key=$oldKey;Register-Toggle|Out-Null
  [System.Windows.Forms.MessageBox]::Show('Atalho indisponível. Escolha outra combinação.')|Out-Null
 }
})
$button.Add_Click({Toggle-Macro})
$form.add_ToggleRequested({Toggle-Macro})
$form.add_StopRequested({Stop-Macro})
$save.Add_Click({
 try {@{sequence=$sequence.Text;title=$title.Text;mods=$script:mods;key=$script:key;shortcut=$hotkey.Text}|ConvertTo-Json|Set-Content -LiteralPath $config -Encoding UTF8;[System.Windows.Forms.MessageBox]::Show('Configuração salva.')|Out-Null}
 catch{[System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'Erro ao salvar')|Out-Null}
})
$timer=New-Object System.Windows.Forms.Timer;$timer.Interval=20
$clock=[System.Diagnostics.Stopwatch]::StartNew()
$timer.Add_Tick({
 if(-not $script:running){return}
 if([MacroWindow]::ActiveTitle().IndexOf($title.Text,[StringComparison]::OrdinalIgnoreCase) -lt 0){$status.Text='Pausado: coloque a janela do jogo em primeiro plano.';return}
 $status.Text='Executando. Use o atalho configurado para desligar.'
 if($clock.ElapsedMilliseconds -lt $script:due){return}
 $step=$script:steps[$script:index]
 if(-not [MacroWindow]::Press([ushort]$step.key)){Stop-Macro;$status.Text='O Windows bloqueou o envio de teclas. Sequência interrompida.';return}
 $script:due=$clock.ElapsedMilliseconds+$step.delay
 $script:index=($script:index+1)%$script:steps.Count
})
$form.Add_Shown({
 if($script:key -ne 0 -and -not (Register-Toggle)){$status.Text='Atalho salvo indisponível. Escolha outra combinação.'}
 $timer.Start()
})
$form.Add_FormClosed({$timer.Stop();$timer.Dispose();[MacroWindow]::UnregisterHotKey($form.Handle,1)|Out-Null;[MacroWindow]::UnregisterHotKey($form.Handle,2)|Out-Null})
[System.Windows.Forms.Application]::Run($form)
