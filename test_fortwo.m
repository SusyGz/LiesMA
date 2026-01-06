%% % builder_test_dualScreen_C.m


Screen('Preference', 'SkipSyncTests', 1);

%% ------------------- Tabelle vorbereiten -------------------
dataTable = table();  %  initialisieren

%% ----------- Gewinn-Variablen initialisieren -----------

% EEG-Person
EEG_gainBlock  = 0;   % Gewinn der EEG-Person für den aktuellen Block
EEG_gainTotal  = 0;   % Gesamter Gewinn der EEG-Person über alle Blöcke

% Partner-Person
Partner_gainBlock  = 0;   % Gewinn Partner für den aktuellen Block
Partner_gainTotal  = 0;   % Gesamter Gewinn Partner






    KbName('UnifyKeyNames');

%% -------------------- VP-Abfrage --------------------
prompt = {'Bitte geben Sie die VP-ID ein:'};
dlgtitle = 'VP-Auswahl';
dims = [1 40];
definput = {'demo'};
answer = inputdlg(prompt, dlgtitle, dims, definput);
if isempty(answer)
    error('Keine VP-ID eingegeben. Experiment abgebrochen.');
end
vpID = answer{1};



%% ------------------- Screen Setup/ Voreinstellungen -------------------
screens = Screen('Screens');
if numel(screens) < 1
    error('Keine Bildschirme gefunden.');
end

% EEG = primärer Monitor (1) ; Partner = sekundär (max)
eegScreenNumber = 1;
partnerScreenNumber = max(screens);

black = BlackIndex(eegScreenNumber);
white = WhiteIndex(eegScreenNumber);

% EEG-Fenster
[winEEG, winRectEEG] = Screen('OpenWindow', eegScreenNumber, black);
[xCenterEEG, yCenterEEG] = RectCenter(winRectEEG);

% Partner-Fenster
[winPartner, winRectPartner] = Screen('OpenWindow', partnerScreenNumber, black);
[xCenterPartner, yCenterPartner] = RectCenter(winRectPartner);

% ViewPixx marker 
topLeftPixel = [0 0 1 1];
VpixxMarkerZero = @(windowPointer) Screen('FillRect', windowPointer, [0 0 0], topLeftPixel);
setVpixxMarker  = @(windowPointer, value) Screen('FillRect', windowPointer, [value 0 0], topLeftPixel);

% Initiale Nullmarker + Flip
VpixxMarkerZero(winEEG); VpixxMarkerZero(winPartner);
Screen('Flip', winEEG);
Screen('Flip', winPartner);

% --- waiting icon ---
waitIconImg = imread('C:\Users\chris\Desktop\Masterarbeit\Matlab\Experiment\code\wait_message.png'); 
if size(waitIconImg,3) == 1
    waitIconImg = repmat(waitIconImg,[1 1 3]);
end
waitIconTex = Screen('MakeTexture', winPartner, waitIconImg);

% Icon-Größe
[iconH, iconW, ~] = size(waitIconImg);
iconScale = 0.25;
iconW = iconW * iconScale;
iconH = iconH * iconScale;

baseRect = [0 0 iconW iconH];

% Position Icon 
waitIconRectPartner = CenterRectOnPointd( ...
    baseRect, ...
    winRectPartner(3)/2, ...
    winRectPartner(4)/2 );

waitIconRectEEG = CenterRectOnPointd( ...
    baseRect, ...
    winRectEEG(3)/2, ...
    winRectEEG(4)/2 );

% Text / Cursor Einstellungen 
Screen('TextFont', winEEG, 'Verdana'); Screen('TextSize', winEEG, 45);
Screen('TextFont', winPartner, 'Verdana'); Screen('TextSize', winPartner, 45);

HideCursor(eegScreenNumber);          % EEG-Cursor unsichtbar
ShowCursor(partnerScreenNumber);      % Partner-Cursor sichtbar


%% ------------------- INSTRUKTIONEN ------------------- %%
%%-------------------------------------------------------%%
instrEEG = ['Willkommen!\n\nDu bist ein Händler und verkaufst verschiedene Objekte.\n\n' ...
            'Manche davon sind echt, andere sind Fälschungen.\n\n' ...
            'Dein Ziel: so viel Gewinn wie möglich zu machen.\n\n' ...
            'Drücke LEERTASTE, wenn du bereit bist.'];

instrPartner = ['Willkommen!\n\nDu bist ein Händler und kaufst und verkaufst verschiedene Objekte.\n\n' ...
            'Manche davon sind echt, manche Fälschungen.\n\n' ...
            'Dein Ziel: so viel Gewinn wie möglich zu machen und Fälschungen zu vermeiden.\n\n' ...
            'Klicke auf den Button unten, wenn du bereit bist.'];

%  Format
DrawFormattedText(winEEG, instrEEG, 'center', 'center', white, [], [], [], 1.2); %für EEG

DrawFormattedText(winPartner, instrPartner, 'center', winRectPartner(4)*0.25, white, [], [], [], 1.2); %für Partner 

%%  "Ich bin bereit" - Button (Partner) - Format und Position 
buttonW = 350;
buttonH = 90;
buttonRect = CenterRectOnPoint([0 0 buttonW buttonH], winRectPartner(3)/2, winRectPartner(4)*0.75);

Screen('FillRect', winPartner, [80 80 80], buttonRect);
DrawFormattedText(winPartner, 'Weiter', 'center', 'center', white, [], [], [], 1.2, [], buttonRect);

%% Marker  + Flip
markerValue = 33; % Marker
setVpixxMarker(winEEG, markerValue);
setVpixxMarker(winPartner, markerValue);

flipTimeEEG = Screen('Flip', winEEG);
flipTimePartner = Screen('Flip', winPartner); % speicherung Flip-zeitpunkte

HideCursor(eegScreenNumber);          
ShowCursor(partnerScreenNumber);      

VpixxMarkerZero(winEEG); % Marker wieder auf 0 setzen 
VpixxMarkerZero(winPartner);

triggerLog = [];  % initial Trigger-Log
triggerLog(end+1,:) = [markerValue, flipTimeEEG, flipTimePartner];

%% -- Beide bereit? --
eegReady = false;
partnerReady = false;

SetMouse(winRectPartner(3)/2, winRectPartner(4)/2, partnerScreenNumber); % Maus in die Mitte des Partner-Screens setzen

waitText = 'Bitte warten...\n\nDie andere Person ist noch nicht bereit.'; % Warte-Text vorbereiten

while ~(eegReady && partnerReady)
    %% --- EEG: Leertaste für Weiter ---
    [keyDown,~,kc] = KbCheck;
    if keyDown
        k = KbName(kc);
        if iscell(k), k = k{1}; end
        if strcmpi(k,'space')
            eegReady = true;
            WaitSecs(0.2); 
        end
    end

    %% --- Partner: Auf "Weiter" clicken ---
    [mx, my, buttons] = GetMouse(partnerScreenNumber);
    if any(buttons)
        if mx >= buttonRect(1) && mx <= buttonRect(3) && ...
           my >= buttonRect(2) && my <= buttonRect(4)
            partnerReady = true;
            WaitSecs(0.2); 
        end
    end

    %% EEG Screen warte screen/ instruction 
    Screen('FillRect', winEEG, black);
    if eegReady && ~partnerReady
        DrawFormattedText(winEEG, waitText, ...
            'center', 'center', white, [], [], [], 1.2); %Falls Partner noch nicht ready dann "Bitte Warten"
    else
        DrawFormattedText(winEEG, instrEEG, ...
            'center', 'center', white, [], [], [], 1.2); % Beide Ready? Dann Instruktionen
    end
    Screen('Flip', winEEG);

    %% Partner Screen warte screen / instruction 
    Screen('FillRect', winPartner, black);
    if partnerReady && ~eegReady
        DrawFormattedText(winPartner, waitText, ...
            'center', 'center', white, [], [], [], 1.2);
    else
        DrawFormattedText(winPartner, instrPartner, ...
            'center', winRectPartner(4)*0.25, white, [], [], [], 1.2);

        % Button nur anzeigen, wenn Partner noch nicht ready
        if ~partnerReady
            Screen('FillRect', winPartner, [80 80 80], buttonRect);
            DrawFormattedText(winPartner, 'Weiter', ...
                'center', 'center', white, [], [], [], 1.2, [], buttonRect);
        end
    end
    Screen('Flip', winPartner);

    HideCursor(eegScreenNumber);
    ShowCursor(partnerScreenNumber);

    WaitSecs(0.01);
end


%Beide bereit: Weiter geht's...

markerValue = 33; % ready-marker
setVpixxMarker(winEEG, markerValue);
setVpixxMarker(winPartner, markerValue);

flipTimeEEG = Screen('Flip', winEEG);
flipTimePartner = Screen('Flip', winPartner);

HideCursor(eegScreenNumber);
ShowCursor(partnerScreenNumber);

VpixxMarkerZero(winEEG); 
VpixxMarkerZero(winPartner);
triggerLog(end+1,:) = [markerValue, flipTimeEEG, flipTimePartner];

%% -------------BLOCK INITIALISIEREN ---------------%%
%%--------------------------------------------------%%

    nBlocks = 1;  % später erhöhen

    for block = 1:nBlocks
        
        fprintf('\n--- BLOCK %d ---\n', block);
        
        blockProfit_EEG = 0;
        blockProfit_Partner = 0; % Gewinne von Block zurücksetzen auf 0 



%% ------------------- Stimuli / Objects Definition aus Excel -------------------
stimTable = readtable('stimuli.xlsx');

% Objekte
objects = stimTable.Name;           % Objekt-Namen
imagePaths = stimTable.Bild;        % Bildpfaden

% Preisoptionen vorbereiten 
priceOptions = cell(height(stimTable),1);
for i = 1:height(stimTable)
    opts = strsplit(stimTable.PreisOptionen{i}, ';');
    priceOptions{i} = opts;
end

%  Wert + Risiko
descriptions = cell(height(stimTable),1);
for i = 1:height(stimTable)
    descriptions{i} = sprintf('Value: %s€\nRisk: %s', string(stimTable.Wert(i)), string(stimTable.Risiko(i)));
end

nItems = numel(objects);

% 2 zufällige paare auswählen
pairIDs = stimTable.PaarID;

uniquePairs = unique(pairIDs);
randPairs = datasample(uniquePairs, 2, 'Replace', false); % hier falls ich anzahl der stimuli ändern will 
showIdx = find(ismember(pairIDs, randPairs));

nItems = numel(showIdx);   

% Info-Texte vorbereiten (für Partner)
infoTexts = cell(height(stimTable), 1);
for i = 1:height(stimTable)
    infoRaw = string(stimTable.Info{i});  
    
    if infoRaw == ""
        infoTexts{i} = "";
    else
        parts = strsplit(infoRaw, ';');
        infoStr = "";
        for j = 1:numel(parts)
            infoStr = infoStr + "• " + strtrim(parts(j)) + "\n";
        end
        infoTexts{i} = infoStr;
    end
end


% Reduzierte Info vorbereiten (für EEG) 
infoRedTexts = cell(height(stimTable), 1);

for i = 1:height(stimTable)
    infoRaw = string(stimTable.InfoRed{i}); 
    
    if infoRaw == ""
        infoRedTexts{i} = "";
    else
        parts = strsplit(infoRaw, ';');
        infoStr = "";
        for j = 1:numel(parts)
            infoStr = infoStr + "• " + strtrim(parts(j)) + "\n";
        end
        infoRedTexts{i} = infoStr;
    end
end


    %% --- Layout für Objekte zur Auswahl (EEG) ---
    margin = 40;
    rowGap = 20;
    availableH = winRectEEG(4) - 2*margin;
    rowH = floor((availableH - (nItems-1)*rowGap) / nItems);
    leftColW = round(winRectEEG(3) * 0.30);
    thumbMaxH = rowH - 20;
    thumbMaxW = leftColW - 20;

%% --- Load images & make textures (EEG) ---
tex = zeros(1, nItems);
texSizes = zeros(nItems, 2);

for i = 1:nItems
    realIdx = showIdx(i);

    try
        tmp = imread(imagePaths{realIdx});
        if size(tmp,3) == 1
            tmp = repmat(tmp,[1 1 3]);
        end

        [hImg, wImg, ~] = size(tmp);

        % Einheitliche Bildgröße
        scale = min([thumbMaxW / wImg, thumbMaxH / hImg, 1]);
        newW = max(1, round(wImg * scale));
        newH = max(1, round(hImg * scale));

        imgResized = imresize(tmp, [newH newW]);

        tex(i) = Screen('MakeTexture', winEEG, imgResized);
        texSizes(i,:) = [newW newH];

    catch
        %falls Bild fehlt / kaputt
        tex(i) = 0;
        texSizes(i,:) = [thumbMaxW, thumbMaxH];
    end
end

    %% ------------------- OBJEKTE ZEICHNEN FÜR EEG (Partner sieht 'Bitte warten') -------------------
    %%------------------------------------------------------------------------------------------------
    Screen('FillRect', winEEG, black);
    % Partner - simple waiting text 
    DrawFormattedText(winPartner, 'Partner: Bitte warten...', 'center', 'center', white, [], [], [], 1.2);

    % Layout object list
    for i = 1:nItems
        yTop = margin + (i-1)*(rowH + rowGap);
        yBottom = yTop + rowH;

        imgCenterX = margin + round(leftColW/2);
        imgCenterY = yTop + round(rowH/2);

        % feste Bildbox (gleich groß für alle)
        boxW = thumbMaxW;
        boxH = thumbMaxH;

        boxRect = CenterRectOnPoint( ...
            [0 0 boxW boxH], imgCenterX, imgCenterY);

% # hier überprüfen ob etwas doppelt drin ist
        % if tex(i) ~= 0
        %     % echte Bildgröße (bereits skaliert)
        %     imgW = texSizes(i,1);
        %     imgH = texSizes(i,2);
        % 
        %     imgRect = CenterRectOnPoint( ...
        %         [0 0 imgW imgH], imgCenterX, imgCenterY);
        % 
        %     Screen('DrawTexture', winEEG, tex(i), [], imgRect);
        % end
        % 
        % destW = texSizes(i,1);
        % destH = texSizes(i,2);
        % destRect = [imgCenterX-destW/2, imgCenterY-destH/2, imgCenterX+destW/2, imgCenterY+destH/2];
        % 
        % if tex(i) ~= 0 
        %     Screen('DrawTexture', winEEG, tex(i), [], destRect);
        % else
        %     phRect = [margin+10, yTop+10, margin+10+thumbMaxW, yTop+10+thumbMaxH];
        %     Screen('FrameRect', winEEG, white, phRect, 3); % Platzhalter, falls Bild fehlt
        %     DrawFormattedText(winEEG, 'No image', phRect(1), phRect(2)+round(thumbMaxH/2)-10, white, thumbMaxW);
        % end
% # bis hier 
% Neue Version 

% Stimulusbild oder Platzhalter zeichnen 
if tex(i) ~= 0
    % Position und Format/ Skalierung
    imgW = texSizes(i,1);
    imgH = texSizes(i,2);

    imgRect = CenterRectOnPoint( ...
        [0 0 imgW imgH], imgCenterX, imgCenterY);  % Bildrechteck zentriert in Bildbox


    Screen('DrawTexture', winEEG, tex(i), [], imgRect);     % Stimulusbild zeichnen

else
    % Platzhalter anzeigen, falls kein Bild verfügbar ist (damit es nicht
    % crashed)
    phRect = [ ...
        imgCenterX - thumbMaxW/2, ...
        imgCenterY - thumbMaxH/2, ...
        imgCenterX + thumbMaxW/2, ...
        imgCenterY + thumbMaxH/2 ];

    Screen('FrameRect', winEEG, white, phRect, 3);
    DrawFormattedText(winEEG, 'No image', ...
        phRect(1), phRect(2) + round(thumbMaxH/2) - 10, ...
        white, thumbMaxW);
end

        % Beschreibungen neben Bild
        textRect = [margin+leftColW+20, yTop+10, winRectEEG(3)-margin, yBottom-10]; % beschreibungstext rechts
        realIdx = showIdx(i);

        % OriginalFake-Spalte hinzufügen (nur EEG)
        origFake = string(stimTable.OriginalFake(realIdx));

        % Objektname + OriginalFake in Klammern + Beschreibung
        infoText = sprintf('%s (%s)\n\n%s', objects{realIdx}, origFake, descriptions{realIdx});

        DrawFormattedText(winEEG, infoText, ...
            'center', 'center', white, [], [], [], 1.2, [], textRect); % Objektname (Fake), Beschreibung rechts neben Bild



        % Objekt Nummer Links vom Bild
        numLabel = sprintf('%d', i);
        numX = margin + 8;
        numY = yTop + round(rowH/2)-18;
        % Screen('TextSize', winEEG, 45);
        DrawFormattedText(winEEG, numLabel, numX, numY, white);
        % Screen('TextSize', winEEG, 45);
    end

    % Marker + Flip on both screens (EEG and Partner)
    markerValue = 33;
    setVpixxMarker(winEEG, markerValue);
    setVpixxMarker(winPartner, markerValue);
    flipTimeEEG = Screen('Flip', winEEG);
    flipTimePartner = Screen('Flip', winPartner);
    VpixxMarkerZero(winEEG); VpixxMarkerZero(winPartner);
    triggerLog(end+1,:) = [markerValue, flipTimeEEG, flipTimePartner];

    %% -Objekt wählen und RT messen -
    keysAllowed = arrayfun(@num2str, 1:nItems, 'UniformOutput', false);
    chosenObj = NaN;
    tStart = GetSecs;
    while isnan(chosenObj)
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            pressed = KbName(keyCode);
            if iscell(pressed), pressed = pressed{1}; end
            pressed = pressed(1);
            idx = find(strcmp(pressed, keysAllowed), 1);
            if ~isempty(idx)
                chosenObj = showIdx(idx); 
                RT_imageChoice_block = GetSecs - flipTimeEEG; % RT relative to flip

               % Info Aus dem Block speichern
               chosenObjectIdx_block  = chosenObj;
               chosenObjectName_block = objects{chosenObj};
                break;
            end
        end
        WaitSecs(0.01);
    end

    % close textures
    for i = 1:nItems, if tex(i) ~= 0, Screen('Close', tex(i)); end, end



    %% ------------------- PRICE CHOICE -------------------
    %------------------------------------------------------------

prices = priceOptions{chosenObj};
nOptions = numel(prices);

%% --- Bild vorbereiten ---
priceImgPath = imagePaths{chosenObj};
thumbTex = 0; imgW = 0; imgH = 0;

if ~isempty(priceImgPath) && exist(priceImgPath,'file')
    tmp = imread(priceImgPath);
    if size(tmp,3)==1
        tmp = repmat(tmp,[1 1 3]);
    end

    [h0,w0,~] = size(tmp);
    maxW = round(winRectEEG(3)*0.7);
    maxH = round(winRectEEG(4)*0.35);
    scale = min([maxW/w0, maxH/h0, 1]);

    imgW = round(w0*scale);
    imgH = round(h0*scale);

    tmp = imresize(tmp,[imgH imgW]);
    thumbTex = Screen('MakeTexture', winEEG, tmp);
end

%% --- EEG Screen zeichnen (Preiswahl inkl. Bild---
Screen('FillRect', winEEG, black);

centerX = winRectEEG(3)/2;

% Bild oben 
imgCenterY = winRectEEG(4)*0.23;
if thumbTex ~= 0
    imgRect = CenterRectOnPoint([0 0 imgW imgH], centerX, imgCenterY);
    Screen('DrawTexture', winEEG, thumbTex, [], imgRect);
else
    imgRect = CenterRectOnPoint([0 0 500 300], centerX, imgCenterY);
    Screen('FrameRect', winEEG, white, imgRect, 3);
end

% Objektname + Beschreibung 
% Screen('TextSize', winEEG, 42);
textY = imgRect(4) + winRectEEG(4)*0.03;

origFake = string(stimTable.OriginalFake(chosenObj));   % Original/Fake aus Excel
objText = sprintf('%s (%s)\n\n%s', objects{chosenObj}, origFake, descriptions{chosenObj});

DrawFormattedText(winEEG, objText, ...
    'center', textY, white, 70, [], [], 1.2);

% Preisoptionen nebeneinander 
% Screen('TextSize', winEEG, 50);

optionY = winRectEEG(4)*0.78;
xOffset = winRectEEG(3)*0.18;

optX = [centerX - xOffset, centerX + xOffset];

for i = 1:nOptions
    DrawFormattedText(winEEG, ...
        sprintf('%s €', prices{i}), ...
        optX(i), optionY, white, [], [], [], 1.2);
end


%% --- Partner Screen (Warte-Screen)---
Screen('FillRect', winPartner, black);
DrawFormattedText(winPartner, ...
    'Partner: Beobachte die Entscheidung des EEG-Teilnehmers...', ...
    'center', 'center', white);

%% --- Marker + Flip ---
markerValue = 33;
setVpixxMarker(winEEG, markerValue);
setVpixxMarker(winPartner, markerValue);

flipTimeEEG = Screen('Flip', winEEG);
flipTimePartner = Screen('Flip', winPartner);

VpixxMarkerZero(winEEG);
VpixxMarkerZero(winPartner);

triggerLog(end+1,:) = [markerValue, flipTimeEEG, flipTimePartner];

%% --- Tasteneingabe ---
chosenPriceIdx = NaN;
while isnan(chosenPriceIdx)
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown

        if keyCode(KbName('LeftArrow'))
            chosenPriceIdx = 1;   % linker Preis
            RT_price = GetSecs - flipTimeEEG;

        elseif keyCode(KbName('RightArrow'))
            chosenPriceIdx = 2;  % rechter Preis
            RT_price = GetSecs - flipTimeEEG;
        end
    end
    WaitSecs(0.01);
end



chosenPrice = prices{chosenPriceIdx};

if thumbTex ~= 0
    Screen('Close', thumbTex);
end
% 
% %% ================= ANGEBOT SUMMARY + INFOS =================
% 
% % ---------- EEG: Angebot Summary vorbereiten ----------
% Screen('FillRect', winEEG, black); 
% 
% finalTex = 0;
% if exist(imagePaths{chosenObj}, 'file')
%     finalImg = imread(imagePaths{chosenObj});
%     if size(finalImg,3)==1
%         finalImg = repmat(finalImg,[1 1 3]);
%     end
% 
%     [h0,w0,~] = size(finalImg);
% 
%     % Feste Bounding-Box, Skalierung und Position des Bildes
%     maxW = round(winRectEEG(3) * 0.55);
%     maxH = round(winRectEEG(4) * 0.35);
% 
%     scale = min([maxW/w0, maxH/h0, 1]);
%     newW = round(w0 * scale);
%     newH = round(h0 * scale);
% 
%     finalImg = imresize(finalImg, [newH newW]);
%     finalTex = Screen('MakeTexture', winEEG, finalImg);
% 
%     imgRectFinal = CenterRectOnPoint( ...
%         [0 0 newW newH], ...
%         winRectEEG(3)/2, winRectEEG(4)*0.28);
% 
%     Screen('DrawTexture', winEEG, finalTex, [], imgRectFinal); 
% end
% 
% 
% % Screen('TextSize', winEEG, 45); %Text für final Summary
% finalText = sprintf( ...
%     'Final selection:\n\nObject: %s\nPrice: %s €', ...
%     objects{chosenObj}, chosenPrice);
% 
% DrawFormattedText(winEEG, finalText, ...
%     'center', winRectEEG(4)*0.55, white, 70, [], [], 1.2);
% 
% % Reduzierte Info anzeigen im EEG (Bekommt weniger Info als Partner)
% % Screen('TextSize', winEEG, 32);
% 
% currentInfoRed = char(infoRedTexts{chosenObj}); 
% 
% DrawFormattedText(winEEG, currentInfoRed, ...
%     'center', winRectEEG(4)*0.70, white, 70, [], [], 1.2);
% 
% 
% 
% 
% % ---------- Partner: Offer Summary vorbereiten ----------
% Screen('FillRect', winPartner, black);
% 
% % Screen('TextSize', winPartner, 48);
% DrawFormattedText(winPartner, 'Angebot', ...
%     'center', winRectPartner(4)*0.08, white);
% 
% % Objektbild
% offerTex = 0;
% if exist(imagePaths{chosenObj}, 'file')
%     tmp = imread(imagePaths{chosenObj});
%     if size(tmp,3)==1
%         tmp = repmat(tmp,[1 1 3]);
%     end
% 
%     [h0,w0,~] = size(tmp);
% 
%     % Feste Bounding-Box (Partner)
%     maxW = round(winRectPartner(3) * 0.50);
%     maxH = round(winRectPartner(4) * 0.35);
% 
%     scale = min([maxW/w0, maxH/h0, 1]);
%     newW = round(w0 * scale);
%     newH = round(h0 * scale);
% 
%     tmp = imresize(tmp,[newH newW]);
%     offerTex = Screen('MakeTexture', winPartner, tmp);
% 
%     imgRect = CenterRectOnPoint( ...
%         [0 0 newW newH], ...
%         winRectPartner(3)/2, winRectPartner(4)*0.40);
% 
%     Screen('DrawTexture', winPartner, offerTex, [], imgRect);
% end
% 
% % Preis anzeigen
% % Screen('TextSize', winPartner, 40);
% DrawFormattedText(winPartner, ...
%     sprintf('Preis: %s €', chosenPrice), ...
%     'center', winRectPartner(4)*0.75, white);
% 
% 
% % ---------- GEMEINSAMER FLIP ----------
% markerValue = 25;
% setVpixxMarker(winEEG, markerValue);
% setVpixxMarker(winPartner, markerValue);
% 
% flipTimeEEG     = Screen('Flip', winEEG);
% flipTimePartner = Screen('Flip', winPartner);
% 
% VpixxMarkerZero(winEEG);
% VpixxMarkerZero(winPartner);
% 
% triggerLog(end+1,:) = [markerValue flipTimeEEG flipTimePartner];
% 
% 
% 
% %% Partner: Click für Weiter
% 
% clicked = false;
% 
% % Button-Position
% buttonW = 300;
% buttonH = 90;
% buttonRect = CenterRectOnPoint([0 0 buttonW buttonH], ...
%     winRectPartner(3)/2, winRectPartner(4)*0.88);
% 
% % --- Objekttextur vorbereiten --- schauen ob redunant...
% % offerTex = 0;
% % if exist(imagePaths{chosenObj}, 'file')
% %     tmp = imread(imagePaths{chosenObj});
% %     if size(tmp,3)==1
% %         tmp = repmat(tmp,[1 1 3]);
% %     end
% % 
% %     [h0,w0,~] = size(tmp);
% % 
% %     % Feste Bounding-Box (Partner)
% %     maxW = round(winRectPartner(3) * 0.50);
% %     maxH = round(winRectPartner(4) * 0.35);
% % 
% %     scale = min([maxW/w0, maxH/h0, 1]);
% %     newW = round(w0 * scale);
% %     newH = round(h0 * scale);
% % 
% %     tmp = imresize(tmp,[newH newW]);
% %     offerTex = Screen('MakeTexture', winPartner, tmp);
% % 
% %     imgRect = CenterRectOnPoint( ...
% %         [0 0 newW newH], ...
% %         winRectPartner(3)/2, winRectPartner(4)*0.40);
% % 
% %     Screen('DrawTexture', winPartner, offerTex, [], imgRect);
% % end
% 
% %bis hier.. 
% 
% % marker nur einmal senden
% markerSent = false;
% 
% while ~clicked %wartern auf click
% 
%     Screen('FillRect', winPartner, black);
% 
%     % Titel
%     % Screen('TextSize', winPartner, 48);
%     DrawFormattedText(winPartner, 'Angebot', ...
%         'center', winRectPartner(4)*0.08, white);
% 
%     % Objektbild
%     if offerTex ~= 0
%         Screen('DrawTexture', winPartner, offerTex, [], imgRect);
%     end
% 
%     % Preis
%     % Screen('TextSize', winPartner, 40);
%     priceText = sprintf('Preis: %s', chosenPrice);
%     DrawFormattedText(winPartner, priceText, ...
%         'center', winRectPartner(4)*0.75, white);
% 
%     % Info anzeigen (Partner sieht mehr als EEG)
%     % Screen('TextSize', winPartner, 30);
%     currentInfo = char(infoTexts{chosenObj});  
%     DrawFormattedText(winPartner, currentInfo, ...
%     'center', winRectPartner(4)*0.55, white);
% 
% 
% 
%     % Button
%     Screen('FillRect', winPartner, [100 100 100], buttonRect);
%     DrawFormattedText(winPartner, 'Weiter', ...
%         'center', 'center', white, [], [], [], 1.2, [], buttonRect);
% 
%     % Flip + Marker
%     if ~markerSent
%         markerValue = 25;
%         setVpixxMarker(winEEG, markerValue);
%         setVpixxMarker(winPartner, markerValue);
%         flipTimePartner = Screen('Flip', winPartner);
%         VpixxMarkerZero(winEEG);
%         VpixxMarkerZero(winPartner);
%         triggerLog(end+1,:) = [markerValue NaN flipTimePartner];
%         markerSent = true;
%     else
%         Screen('Flip', winPartner);
%     end
% 
%     % Mausabfrage
%     [mx, my, buttons] = GetMouse(partnerScreenNumber);
%     if any(buttons)
%         if mx >= buttonRect(1) && mx <= buttonRect(3) && ...
%            my >= buttonRect(2) && my <= buttonRect(4)
%             clicked = true;
%             WaitSecs(0.2); 
%         end
%     end
% 
%     WaitSecs(0.01);
% end
% 
% % Aufräumen
% if offerTex ~= 0
%     Screen('Close', offerTex);
% end


%%% NEUE VERSION TEST %%%
%% ================= ANGEBOT SUMMARY + INFOS =================

% ---------- EEG: Angebot Summary vorbereiten ----------
Screen('FillRect', winEEG, black); 

% Spalten definieren
leftColX_EEG  = winRectEEG(3) * 0.30;   % Bild links
rightColX_EEG = winRectEEG(3) * 0.65;   % Text rechts

% --- Bild ---
finalTex = 0;
if exist(imagePaths{chosenObj}, 'file')
    finalImg = imread(imagePaths{chosenObj});
    if size(finalImg,3)==1
        finalImg = repmat(finalImg,[1 1 3]);
    end
    [h0,w0,~] = size(finalImg);

    maxW = round(winRectEEG(3) * 0.55);
    maxH = round(winRectEEG(4) * 0.35);

    scale = min([maxW/w0, maxH/h0, 1]);
    newW = round(w0 * scale);
    newH = round(h0 * scale);

    finalImg = imresize(finalImg, [newH newW]);
    finalTex = Screen('MakeTexture', winEEG, finalImg);

    imgRectFinal = CenterRectOnPoint([0 0 newW newH], ...
        leftColX_EEG, winRectEEG(4)*0.40);

    Screen('DrawTexture', winEEG, finalTex, [], imgRectFinal); 
end

% --- Text (Summary) -- 1-
% Screen('TextSize', winEE  2G,  45);
origFake = string(stimTable.OriginalFake(chosenObj));  % Original/Fake aus Excel
finalText = sprintf('Final selection:\n\nObject: %s (%s)\nPrice: %s €', ...
    objects{chosenObj}, origFake, chosenPrice);


DrawFormattedText(winEEG, finalText, ...
    rightColX_EEG - 200, winRectEEG(4)*0.25, white, 70, [], [], 1.2);

% --- Reduzierte Info für EEG ---
currentInfoRed = char(infoRedTexts{chosenObj});
DrawFormattedText(winEEG, currentInfoRed, ...
    rightColX_EEG - 200, winRectEEG(4)*0.45, white, 70, [], [], 1.2);


%% ---------- Partner: Offer Summary vorbereiten ----------
Screen('FillRect', winPartner, black); 

% Spalten definieren
leftColX_P   = winRectPartner(3) * 0.30;
rightColX_P  = winRectPartner(3) * 0.65;

% --- Titel ---
% Screen('TextSize', winPartner, 48);
DrawFormattedText(winPartner, 'Angebot', 'center', winRectPartner(4)*0.08, white);

% --- Bild ---
offerTex = 0;
if exist(imagePaths{chosenObj}, 'file')
    tmp = imread(imagePaths{chosenObj});
    if size(tmp,3)==1
        tmp = repmat(tmp,[1 1 3]);
    end
    [h0,w0,~] = size(tmp);

    maxW = round(winRectPartner(3) * 0.50);
    maxH = round(winRectPartner(4) * 0.35);

    scale = min([maxW/w0, maxH/h0, 1]);
    newW = round(w0 * scale);
    newH = round(h0 * scale);

    tmp = imresize(tmp,[newH newW]);
    offerTex = Screen('MakeTexture', winPartner, tmp);

    imgRect = CenterRectOnPoint([0 0 newW newH], leftColX_P, winRectPartner(4)*0.40);
    Screen('DrawTexture', winPartner, offerTex, [], imgRect);
end

% --- Preis rechts ---
% Screen('TextSize', winPartner, 40);
priceText = sprintf('Preis: %s €', chosenPrice);
DrawFormattedText(winPartner, priceText, rightColX_P - 200, winRectPartner(4)*0.25, white);

% --- Volle Infos rechts ---
% Screen('TextSize', winPartner, 36);
currentInfo = char(infoTexts{chosenObj});
DrawFormattedText(winPartner, currentInfo, rightColX_P - 200, winRectPartner(4)*0.40, white, 70, [], [], 1.2);

% --- Button "Weiter" ---
buttonW = 300; buttonH = 90;
buttonRect = CenterRectOnPoint([0 0 buttonW buttonH], winRectPartner(3)/2, winRectPartner(4)*0.88);
Screen('FillRect', winPartner, [100 100 100], buttonRect);
DrawFormattedText(winPartner, 'Weiter', 'center', 'center', white, [], [], [], 1.2, [], buttonRect);

% --- Flip + Marker ---
markerValue = 33;
setVpixxMarker(winEEG, markerValue);
setVpixxMarker(winPartner, markerValue);

flipTimeEEG     = Screen('Flip', winEEG);
flipTimePartner = Screen('Flip', winPartner);

VpixxMarkerZero(winEEG);
VpixxMarkerZero(winPartner);
triggerLog(end+1,:) = [markerValue flipTimeEEG flipTimePartner];

% --- Partner klickt auf "Weiter" ---
clicked = false;
markerSent = false;

while ~clicked
    Screen('FillRect', winPartner, black);

    % Titel
    DrawFormattedText(winPartner, 'Angebot', 'center', winRectPartner(4)*0.08, white);

    % Bild
    if offerTex ~= 0
        Screen('DrawTexture', winPartner, offerTex, [], imgRect);
    end

    % Preis rechts
    DrawFormattedText(winPartner, priceText, rightColX_P - 200, winRectPartner(4)*0.25, white);

    % Info rechts
    DrawFormattedText(winPartner, currentInfo, rightColX_P - 200, winRectPartner(4)*0.40, white, 70, [], [], 1.2);

    % Button
    Screen('FillRect', winPartner, [100 100 100], buttonRect);
    DrawFormattedText(winPartner, 'Weiter', 'center', 'center', white, [], [], [], 1.2, [], buttonRect);

    % Flip + Marker nur einmal
    if ~markerSent
        markerValue = 33;
        setVpixxMarker(winEEG, markerValue);
        setVpixxMarker(winPartner, markerValue);
        flipTimePartner = Screen('Flip', winPartner);
        VpixxMarkerZero(winEEG);
        VpixxMarkerZero(winPartner);
        triggerLog(end+1,:) = [markerValue NaN flipTimePartner];
        markerSent = true;
    else
        Screen('Flip', winPartner);
    end

    % Mausabfrage
    [mx,my,buttons] = GetMouse(partnerScreenNumber);
    if any(buttons)
        if mx >= buttonRect(1) && mx <= buttonRect(3) && my >= buttonRect(2) && my <= buttonRect(4)
            clicked = true;
            WaitSecs(0.2);
        end
    end
    WaitSecs(0.01);
end

% Aufräumen
if offerTex ~= 0
    Screen('Close', offerTex);
end


%% ------------------- FRAGEBOGEN (Partner sucht fragen aus, EEG antwortet) -------------------
%----------------------------------------------------------------------------------------------

% load questions from Excel
questionTable = readtable('questions.xlsx'); 
questions = questionTable.Question;

nRounds = 2; % Anzahl Runden (SPäter erhöhen)
rng('shuffle'); %Fragen randomisieren 
questionsAvailable = questions(randperm(length(questions))); % zufällige Reihenfolge
questionResponses = cell(nRounds,1);

for roundIdx = 1:nRounds % Runden
   
    % Partner wählt aus 3 Fragen 
    if length(questionsAvailable) < 3
        questionPool = questionsAvailable;
    else
        questionPool = questionsAvailable(1:3);
    end
    
    selectedIdx = NaN;
    tPartnerStart = GetSecs;  % Startzeit für Partner-RT
    
    while isnan(selectedIdx) % Partner while-loop (läuft, bis Frage geklickt wurde)
        Screen('FillRect', winPartner, black);
        buttonRects = cell(1,length(questionPool));
        
        % Loop über alle Fragen
        for i = 1:length(questionPool)
            % Screen('TextSize', winPartner, 45);  % Textgröße

            % Textrechteck berechnen, skalierung und position (Butoon passt sich textlänge an)
            textBounds = Screen('TextBounds', winPartner, questionPool{i});
            textWidth = textBounds(3) - textBounds(1);
            textHeight = textBounds(4) - textBounds(2);
            
            paddingX = 20; 
            paddingY = 10; 
            btnW = textWidth + 2*paddingX;
            btnH = textHeight + 2*paddingY;

            totalHeight = sum(btnH + 20); % 20 px Abstand zwischen Boxen
            startY = (winRectPartner(4) - totalHeight)/2 + btnH/2;
            btnYCenter = startY + (i-1)*(btnH + 20);

            btnRect = [0 0 btnW btnH];  % Rechteck von 0,0 starten
            btnRect = CenterRectOnPointd(btnRect, winRectPartner(3)/2, btnYCenter); % genaues Zentrieren

            % Box zeichnen
            Screen('FillRect', winPartner, [80 80 80], btnRect);

            % Text mittig in Box
            DrawFormattedText(winPartner, questionPool{i}, 'center', 'center', white, [], [], [], 1.2, [], btnRect);

            buttonRects{i} = btnRect; %klickbereich speichern
        end

        
        flipTimePartner = Screen('Flip', winPartner);
        ShowCursor(partnerScreenNumber); 
        HideCursor(eegScreenNumber);
        
        % Maus abfragen
        [mx,my,buttons] = GetMouse(partnerScreenNumber);
        if any(buttons)
            for i = 1:length(questionPool)
                if mx >= buttonRects{i}(1) && mx <= buttonRects{i}(3) && ...
                   my >= buttonRects{i}(2) && my <= buttonRects{i}(4)
                    selectedIdx = i;
                    break;
                end
            end
        end
        WaitSecs(0.01);
    end
    RT_partner = GetSecs - tPartnerStart;  % Partner-RT speichern
    
    % --- Frage auf EEG anzeigen ---
    selectedQuestion = questionPool{selectedIdx}; % Eine Frage geht von Partner rüber
    
    % Warte-Icon
    Screen('FillRect', winEEG, black); Screen('DrawTexture', winEEG, waitIconTex, [], waitIconRectEEG); 
        Screen('Flip', winEEG); 
        WaitSecs(0.01); % kleine Pause 
        Screen('FillRect', winEEG, black); 
       
        % Frage anzeigen für EEG
        DrawFormattedText(winEEG, selectedQuestion, 'center', 'center', white, [], [], [], 1.5); 
       
        % Marker setzen 
        markerValue = 33;
        setVpixxMarker(winEEG, markerValue); 
        setVpixxMarker(winPartner, markerValue); 
        flipTimeEEG = Screen('Flip', winEEG);
        flipTimePartner = Screen('Flip', winPartner);
        VpixxMarkerZero(winEEG); VpixxMarkerZero(winPartner);
        triggerLog(end+1,:) = [markerValue, flipTimeEEG, flipTimePartner]; 
        
        % --- EEG-Person antwortet Ja/Nein --- 
        eegAnswer = NaN; 
        tEEGStart = GetSecs; % Startzeit EEG RT
        while isnan(eegAnswer) 
            [keyIsDown, ~, keyCode] = KbCheck; 
            if keyIsDown 
                key = KbName(keyCode); 
                if iscell(key), key = key{1}; end 
                if strcmpi(key,'LeftArrow'), eegAnswer = 'Ja'; end 
                if strcmpi(key,'RightArrow'), eegAnswer = 'Nein'; end 
            end 
            Screen('FillRect', winPartner, black); 

            % Partner Waiting Icon
            Screen('DrawTexture', winPartner, waitIconTex, [], waitIconRectPartner); 
            Screen('Flip', winPartner); 
            WaitSecs(0.01); 
        end 
        RT_EEG = GetSecs - tEEGStart; % EEG RT speichern 

        % EEG: Frage ausblenden, Warte-Icon anzeigen  
        Screen('FillRect', winEEG, black); 
        Screen('DrawTexture', winEEG, waitIconTex, [], waitIconRectEEG); 
        Screen('Flip', winEEG); 
        
        % EEG-Antwort für Partner anzeigen 
        Screen('FillRect', winPartner, black); 
        DrawFormattedText(winPartner, sprintf('EEG-Antwort:\n%s', eegAnswer), 'center', 'center', white); 
        Screen('Flip', winPartner); 
        WaitSecs(1.5);
        
        % Loggen 
        questionResponses{roundIdx} = struct('question', selectedQuestion, ...
            'response', eegAnswer, ...
            'RT', RT_EEG, ...
            'RT_partner', RT_partner);
        
        % Entferne gewählte Frage aus dem Pool 
        questionsAvailable(strcmp(questionsAvailable, selectedQuestion)) = []; 
end

%% ---------------- ABSCHLUSSFRAGE (Angebt Annehmen / Ablehnen)----------
%-------------------------------------------------------------------------

% Angebotsdaten vorbereiten
offerName  = objects{chosenObj};
offerPrice = chosenPrice;
offerImgPath = imagePaths{chosenObj};

% Bild neu laden
offerImg = imread(offerImgPath);
if size(offerImg,3) == 1
    offerImg = repmat(offerImg,[1 1 3]);
end

% Bild skalieren, Layout
[h0, w0, ~] = size(offerImg);

maxW = round(winRectPartner(3) * 0.5);   % max 50% Fensterbreite
maxH = round(winRectPartner(4) * 0.25);  % max 25% Fensterhöhe

scale = min([maxW / w0, maxH / h0, 1]);  

newW = round(w0 * scale);
newH = round(h0 * scale);

offerImg = imresize(offerImg, [newH newW]);
offerTex = Screen('MakeTexture', winPartner, offerImg);

imgRect = CenterRectOnPoint( ...
    [0 0 newW newH], ...
    winRectPartner(3)/2, ...
    winRectPartner(4)*0.25 ...
);

% Partner Angebot anzeigen

Screen('FillRect', winPartner, black);
ShowCursor('Arrow', partnerScreenNumber);

% Objektname
% Screen('TextSize', winPartner, 48);
DrawFormattedText(winPartner, offerName, ...
    'center', winRectPartner(4)*0.07, white);

% Objektbild
Screen('DrawTexture', winPartner, offerTex, [], imgRect);

% Preis
priceText = sprintf('Preis: %s €', offerPrice);
% Screen('TextSize', winPartner, 36);
DrawFormattedText(winPartner, priceText, ...
    'center', winRectPartner(4)*0.45, white);

% Entscheidungsfrage
% Screen('TextSize', winPartner, 32);
DrawFormattedText(winPartner, ...
    'Möchtest du das Angebot vom Verkäufer annehmen?', ...
    'center', winRectPartner(4)*0.52, white);

% Buttons (Ja / Nein)
buttonW = 300; buttonH = 80;
yesRect = CenterRectOnPoint([0 0 buttonW buttonH], winRectPartner(3)/3, winRectPartner(4)*0.7);
noRect  = CenterRectOnPoint([0 0 buttonW buttonH], 2*winRectPartner(3)/3, winRectPartner(4)*0.7);

Screen('FillRect', winPartner, [80 180 80], yesRect);
Screen('FillRect', winPartner, [180 80 80], noRect);
DrawFormattedText(winPartner, 'Ja', 'center', 'center', white, [], [], [], 1.2, [], yesRect);
DrawFormattedText(winPartner, 'Nein', 'center', 'center', white, [], [], [], 1.2, [], noRect);

Screen('Flip', winPartner);

% EEG Warte-text "Partner überlegt, ob angebot angenommen wird"
Screen('FillRect', winEEG, black);
% Screen('TextSize', winEEG, 32);
DrawFormattedText(winEEG, ...
    'Der Käufer überlegt gerade,\nob er das Angebot annehmen will …', ...
    'center', 'center', white, [], [], [], 1.3);
Screen('Flip', winEEG);


%  Mausabfrage 
tStartAngebot = GetSecs; % Start RT
finalResp = '';
while isempty(finalResp)
    [mx, my, buttons] = GetMouse(partnerScreenNumber);
    if any(buttons)
        if mx >= yesRect(1) && mx <= yesRect(3) && my >= yesRect(2) && my <= yesRect(4)
            finalResp = 'Ja';
        elseif mx >= noRect(1) && mx <= noRect(3) && my >= noRect(2) && my <= noRect(4)
            finalResp = 'Nein';
        end
        WaitSecs(0.3);
    end
    WaitSecs(0.01);
end
RT_finalPartner = GetSecs - tStartAngebot; % RT Messen

% --- Gewinn berechnen (EEG) ---
valueEEG = stimTable.Wert(chosenObj);

if strcmp(finalResp, 'Ja')
    EEG_gainThisTrial = str2double(chosenPrice) - valueEEG;
else
    EEG_gainThisTrial = 0;
end

EEG_gainTotal = EEG_gainTotal + EEG_gainThisTrial;

% --- Gewinn berechnen (Partner) ---
resaleValue = stimTable.Weiterverkauf(chosenObj);
priceEEG    = str2double(chosenPrice);

if strcmp(finalResp, 'Ja')
    Partner_gainThisTrial = resaleValue - priceEEG;
else
    Partner_gainThisTrial = 0;
end

Partner_gainTotal = Partner_gainTotal + Partner_gainThisTrial;


%% --------------GEWINN FEEDBACK ------------------
%---------------------------------------------------

%% -------- EEG Screen --------
Screen('FillRect', winEEG, black);

eegGainText = sprintf( ...
    ['Die Entscheidung des Partners: %s\n\n' ...
     'Gewinn in diesem Durchgang: %d €\n' ...
     'Gesamtgewinn: %d €\n\n' ...
     'Drücke die LEERTASTE, um fortzufahren.'], ...
    finalResp, EEG_gainThisTrial, EEG_gainTotal);

DrawFormattedText(winEEG, eegGainText, ...
    'center', 'center', white, [], [], [], 1.2);

%% -------- Partner Screen --------
Screen('FillRect', winPartner, black);

partnerGainText = sprintf( ...
    ['Deine Entscheidung: %s\n\n' ...
     'Gewinn in diesem Durchgang: %d €\n' ...
     'Gesamtgewinn: %d €'], ...
    finalResp, Partner_gainThisTrial, Partner_gainTotal);

DrawFormattedText(winPartner, partnerGainText, ...
    'center', winRectPartner(4)*0.35, white, [], [], [], 1.2);

% Weiter-Button (Partner)
buttonW = 300;
buttonH = 80;
continueRect = CenterRectOnPoint( ...
    [0 0 buttonW buttonH], ...
    winRectPartner(3)/2, ...
    winRectPartner(4)*0.75);

Screen('FillRect', winPartner, [100 100 100], continueRect);
DrawFormattedText(winPartner, 'Weiter', ...
    'center', 'center', white, [], [], [], 1.2, [], continueRect);

%% Gemeinsamer Flip 
Screen('Flip', winEEG);
Screen('Flip', winPartner);

%%  Warten-Text 
waitText = 'Bitte warten...\n\nDie andere Person ist noch nicht bereit.';

eegWaitingShown     = false;
partnerWaitingShown = false;

%%  Weiter 
eegDone     = false;
partnerDone = false;

while ~(eegDone && partnerDone)

    % EEG sieht Feedback, bestätigt mit Leertaste, Wartetext falls früher
    % fertig
    Screen('FillRect', winEEG, black);

    if ~eegDone
        DrawFormattedText(winEEG, eegGainText, ...
            'center', 'center', white, [], [], [], 1.2);
    else
        DrawFormattedText(winEEG, ...
            'Bitte warten...\n\nDer Partner ist noch nicht bereit.', ...
            'center', 'center', white, [], [], [], 1.2);
    end

    Screen('Flip', winEEG);

    % Partner sieht Feedback, button für weiter, Wartetext
    Screen('FillRect', winPartner, black);

    DrawFormattedText(winPartner, partnerGainText, ...
        'center', winRectPartner(4)*0.35, white, [], [], [], 1.2);

    if ~partnerDone
        Screen('FillRect', winPartner, [100 100 100], continueRect);
        DrawFormattedText(winPartner, 'Weiter', ...
            'center', 'center', white, [], [], [], 1.2, [], continueRect);
    else
        DrawFormattedText(winPartner, ...
            'Bitte warten...\n\nDer Verkäufer ist noch nicht bereit.', ...
            'center', winRectPartner(4)*0.8, white);
    end

    Screen('Flip', winPartner);

    % Input EEG Tastatur
    [keyDown,~,kc] = KbCheck;
    if keyDown && ~eegDone
        k = KbName(kc);
        if iscell(k), k = k{1}; end
        if strcmpi(k,'space')
            eegDone = true;
            WaitSecs(0.2);
        end
    end
% Input Partner Maus
    [mx,my,buttons] = GetMouse(partnerScreenNumber);
    if any(buttons) && ~partnerDone
        if mx >= continueRect(1) && mx <= continueRect(3) && ...
           my >= continueRect(2) && my <= continueRect(4)
            partnerDone = true;
            WaitSecs(0.2);
        end
    end

    WaitSecs(0.01);
end


Screen('Close', offerTex);



%% ------------------- Save Data innerhalb Blocks -------------------
nQuestions = numel(questionResponses);

for q = 1:nQuestions
    newRow = table;

    newRow.subject         = {vpID};
    newRow.block           = block;

    % block-feste Werte
    newRow.chosenObject    = {chosenObjectName_block};
    newRow.imageChoiceRT   = RT_imageChoice_block;
    newRow.chosenPrice     = {chosenPrice};
    newRow.priceRT         = RT_price;

    % Fragen
    newRow.question        = {questionResponses{q}.question};
    newRow.questionAnswer  = {questionResponses{q}.response};
    newRow.RT_EEG          = questionResponses{q}.RT;
    newRow.RT_Partner      = questionResponses{q}.RT_partner;

    % Entscheidung
    newRow.angebotAnnehmen = {finalResp};
    newRow.RT_Angebot      = RT_finalPartner;

    % Gewinn
    newRow.EEG_gainTrial   = EEG_gainThisTrial;
    newRow.EEG_gainTotal   = EEG_gainTotal;

    % Trigger
    newRow.triggerLog      = {jsonencode(triggerLog)};

    dataTable = [dataTable; newRow];
end


end
    % %% ------------------- Save Data pro Frage -------------------
    % 
    %     newRow = table;
    %     newRow.subject         = {vpID};
    %     newRow.block           = block;
    %     newRow.chosenObject = {chosenObjectName_block};
    %     newRow.imageChoiceRT   = RT_imageChoice_block;
    %     newRow.chosenPrice     = {chosenPrice};
    %     newRow.priceRT         = RT_price;
    %     newRow.question        = {questionResponses{q}.question};
    %     newRow.questionAnswer  = {questionResponses{q}.response};
    %     newRow.RT_EEG          = questionResponses{q}.RT;          % EEG-Reaktionszeit
    %     newRow.RT_Partner      = questionResponses{q}.RT_partner;  % Partner-Reaktionszeit beim Fragen wählen
    %     newRow.angebotAnnehmen = {finalResp};
    %     newRow.RT_Angebot      = RT_finalPartner;                  % Partner RT bei finaler Entscheidung
    %     newRow.EEG_gainTrial   = EEG_gainThisTrial;                 % Gewinn in diesem Durchgang
    %     newRow.EEG_gainTotal   = EEG_gainTotal;                     % Gesamtgewinn
    %     newRow.triggerLog      = {jsonencode(triggerLog)};
    % 
    %     dataTable = [dataTable; newRow];


    %% --- speichern ---

timestamp = datestr(now,'yyyymmdd_HHMMSS');

% Dateinamen
fileXLSX = sprintf('response_%s_%s.xlsx', vpID, timestamp);
fileCSV  = sprintf('response_%s_%s.csv',  vpID, timestamp);
fileMAT  = sprintf('response_%s_%s.mat',  vpID, timestamp);

% Excel
writetable(dataTable, fileXLSX);

% CSV
writetable(dataTable, fileCSV);

% MATLAB .mat
save(fileMAT, 'dataTable');

fprintf('Daten gespeichert als:\n%s\n%s\n%s\n', fileXLSX, fileCSV, fileMAT);


%% --- Experiment beenden ---
ShowCursor;
Screen('CloseAll');
Priority(0);
