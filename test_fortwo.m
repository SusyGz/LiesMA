%% % builder_test_dualScreen_C.m


Screen('Preference', 'SkipSyncTests', 1);

%% ------------------- Tabelle vorbereiten -------------------
dataTable = table();  % <- Hier initialisieren

try

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



%% ------------------- Screen Setup -------------------
screens = Screen('Screens');
if numel(screens) < 1
    error('Keine Bildschirme gefunden.');
end

% EEG = primärer Monitor (min) ; Partner = sekundär (max)
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

%% ------------------- Text / Cursor Einstellungen -------------------
Screen('TextFont', winEEG, 'Verdana'); Screen('TextSize', winEEG, 28);
Screen('TextFont', winPartner, 'Verdana'); Screen('TextSize', winPartner, 28);

HideCursor(eegScreenNumber);          % EEG-Cursor unsichtbar
ShowCursor(partnerScreenNumber);      % Partner-Cursor sichtbar

%% ------------------- Instruction Screens -------------------
instrEEG = ['Willkommen!\n\nDu bist ein Händler und verkaufst verschiedene Objekte.\n\n' ...
            'Manche davon sind echt, andere sind Fälschungen.\n\n' ...
            'Dein Ziel: so viel Gewinn wie möglich zu machen.\n\n' ...
            'Drücke LEERTASTE, wenn du bereit bist.'];

instrPartner = ['Willkommen!\n\nDu bist ein Händler und kaufst und verkaufst verschiedene Objekte.\n\n' ...
            'Manche davon sind echt, manche Fälschungen.\n\n' ...
            'Dein Ziel: so viel Gewinn wie möglich zu machen und Fälschungen zu vermeiden.\n\n' ...
            'Klicke auf den Button unten, wenn du bereit bist.'];

% --- EEG Text ---
DrawFormattedText(winEEG, instrEEG, 'center', 'center', white, [], [], [], 1.2);

% --- Partner Text ---
DrawFormattedText(winPartner, instrPartner, 'center', winRectPartner(4)*0.25, white, [], [], [], 1.2);

%% -------- Button "Ich bin bereit" (Partner Screen) --------
buttonW = 350;
buttonH = 90;
buttonRect = CenterRectOnPoint([0 0 buttonW buttonH], winRectPartner(3)/2, winRectPartner(4)*0.75);

Screen('FillRect', winPartner, [80 80 80], buttonRect);
DrawFormattedText(winPartner, 'Ich bin bereit', 'center', 'center', black);

%% --- Marker setzen + Flip ---
markerValue = 100;
setVpixxMarker(winEEG, markerValue);
setVpixxMarker(winPartner, markerValue);

flipTimeEEG = Screen('Flip', winEEG);
flipTimePartner = Screen('Flip', winPartner);

HideCursor(eegScreenNumber);          % EEG unsichtbar
ShowCursor(partnerScreenNumber);      % Partner sichtbar

VpixxMarkerZero(winEEG); 
VpixxMarkerZero(winPartner);

triggerLog = [];  % initial Trigger-Log
triggerLog(end+1,:) = [markerValue, flipTimeEEG, flipTimePartner];

%% ------------ WARTEN AUF BEIDE (EEG + Partner) ------------
eegReady = false;
partnerReady = false;

% Maus in die Mitte des Partner-Screens setzen
SetMouse(winRectPartner(3)/2, winRectPartner(4)/2, partnerScreenNumber);

while ~(eegReady && partnerReady)

    %% --- EEG: check space ---
    [keyDown,~,kc] = KbCheck;
    if keyDown
        k = KbName(kc);
        if iscell(k), k = k{1}; end
        if strcmpi(k,'space')
            eegReady = true;
        end
    end

    %% --- Partner: check mouse click ---
    [mx, my, buttons] = GetMouse(partnerScreenNumber);
    if any(buttons)
        if mx >= buttonRect(1) && mx <= buttonRect(3) && ...
           my >= buttonRect(2) && my <= buttonRect(4)
            partnerReady = true;
        end
    end

    % Cursor-Sichtbarkeit erzwingen
    HideCursor(eegScreenNumber);
    ShowCursor(partnerScreenNumber);

    WaitSecs(0.01);
end

%% --- Beide bereit: Weiter geht's ---
markerValue = 101; % ready-marker
setVpixxMarker(winEEG, markerValue);
setVpixxMarker(winPartner, markerValue);

flipTimeEEG = Screen('Flip', winEEG);
flipTimePartner = Screen('Flip', winPartner);

HideCursor(eegScreenNumber);
ShowCursor(partnerScreenNumber);

VpixxMarkerZero(winEEG); 
VpixxMarkerZero(winPartner);
triggerLog(end+1,:) = [markerValue, flipTimeEEG, flipTimePartner];


    nBlocks = 2;  % später erhöhen

    for block = 1:nBlocks
        
        fprintf('\n--- BLOCK %d ---\n', block);


%% ------------------- Stimuli / Objects Definition (EEG) aus Excel -------------------
stimTable = readtable('stimuli.xlsx');

% Objekte
objects = stimTable.Name;           % Zellarray mit Objekt-Namen
imagePaths = stimTable.Bild;        % Zellarray mit Bildpfaden

% Preisoptionen vorbereiten (angenommen in Excel als "20€;200€")
priceOptions = cell(height(stimTable),1);
for i = 1:height(stimTable)
    opts = strsplit(stimTable.PreisOptionen{i}, ';');
    priceOptions{i} = opts;
end

% Beschreibungen aus Wert + Risiko
descriptions = cell(height(stimTable),1);
for i = 1:height(stimTable)
    descriptions{i} = sprintf('Value: %s€\nRisk: %s', string(stimTable.Wert(i)), string(stimTable.Risiko(i)));


end

nItems = numel(objects);

    %% --- Layout für Objekt-List (EEG) ---
    margin = 40;
    rowGap = 20;
    availableH = winRectEEG(4) - 2*margin;
    rowH = floor((availableH - (nItems-1)*rowGap) / nItems);
    leftColW = round(winRectEEG(3) * 0.30);
    thumbMaxH = rowH - 20;
    thumbMaxW = leftColW - 20;

    %% --- Load images & make textures (EEG) ---
    tex = zeros(1, nItems);
    texSizes = zeros(nItems,2);
    for i = 1:nItems
        try
            tmp = imread(imagePaths{i});
            if size(tmp,3) == 1, tmp = repmat(tmp,[1 1 3]); end
            [hImg, wImg, ~] = size(tmp);
            scale = min(thumbMaxW/wImg, thumbMaxH/hImg);
            scale = min(scale, 1);
            newW = max(1, round(wImg*scale));
            newH = max(1, round(hImg*scale));
            imgResized = imresize(tmp, [newH newW]);
            tex(i) = Screen('MakeTexture', winEEG, imgResized);
            texSizes(i,:) = [newW newH];
        catch
            tex(i) = 0;
            texSizes(i,:) = [min(thumbMaxW,200) min(thumbMaxH,120)];
        end
    end

    %% ------------------- Draw objects list on EEG; Partner shows 'Bitte warten' -------------------
    Screen('FillRect', winEEG, black);
    % Partner - simple waiting text (you can change this later)
    DrawFormattedText(winPartner, 'Partner: Bitte warten...', 'center', 'center', white, [], [], [], 1.2);

    for i = 1:nItems
        yTop = margin + (i-1)*(rowH + rowGap);
        yBottom = yTop + rowH;

        imgCenterX = margin + round(leftColW/2);
        imgCenterY = yTop + round(rowH/2);
        destW = texSizes(i,1);
        destH = texSizes(i,2);
        destRect = [imgCenterX-destW/2, imgCenterY-destH/2, imgCenterX+destW/2, imgCenterY+destH/2];

        if tex(i) ~= 0
            Screen('DrawTexture', winEEG, tex(i), [], destRect);
        else
            phRect = [margin+10, yTop+10, margin+10+thumbMaxW, yTop+10+thumbMaxH];
            Screen('FrameRect', winEEG, white, phRect, 3);
            DrawFormattedText(winEEG, 'No image', phRect(1), phRect(2)+round(thumbMaxH/2)-10, white, thumbMaxW);
        end

        % description text on right
        textRect = [margin+leftColW+20, yTop+10, winRectEEG(3)-margin, yBottom-10];
        DrawFormattedText(winEEG, sprintf('%s\n\n%s', objects{i}, descriptions{i}), 'center', 'center', white, [], [], [], 1.2, [], textRect);

        % item number left
        numLabel = sprintf('%d', i);
        numX = margin + 8;
        numY = yTop + round(rowH/2)-18;
        Screen('TextSize', winEEG, 28);
        DrawFormattedText(winEEG, numLabel, numX, numY, white);
        Screen('TextSize', winEEG, 22);
    end

    % Marker + Flip on both screens (EEG and Partner)
    markerValue = 10;
    setVpixxMarker(winEEG, markerValue);
    setVpixxMarker(winPartner, markerValue);
    flipTimeEEG = Screen('Flip', winEEG);
    flipTimePartner = Screen('Flip', winPartner);
    VpixxMarkerZero(winEEG); VpixxMarkerZero(winPartner);
    triggerLog(end+1,:) = [markerValue, flipTimeEEG, flipTimePartner];

    %% ------------------- Wait for object choice (keys 1..nItems) and record RT (EEG) -------------------
    keysAllowed = arrayfun(@num2str, 1:nItems, 'UniformOutput', false);
    chosenObj = NaN;
    tStart = GetSecs;
    while isnan(chosenObj)
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            pressed = KbName(keyCode);
            if iscell(pressed), pressed = pressed{1}; end
            % handle multiple-key strings e.g. '1!' -> pick first char
            pressed = pressed(1);
            idx = find(strcmp(pressed, keysAllowed), 1);
            if ~isempty(idx)
                chosenObj = idx;
                RT_imageChoice = GetSecs - flipTimeEEG; % RT relative to flip
                break;
            end
        end
        WaitSecs(0.01);
    end

    % close textures
    for i = 1:nItems, if tex(i) ~= 0, Screen('Close', tex(i)); end, end

    %% ------------------- Confirmation Screen (both) -------------------
    confirmTextEEG = sprintf('You selected:\n\n%s\n\nPress any key to continue.', objects{chosenObj});
    confirmTextPartner = sprintf('Partner: Teilnehmer hat %s gewählt. Bitte warten...', objects{chosenObj});
    DrawFormattedText(winEEG, confirmTextEEG, 'center', 'center', white, [], [], [], 1.2);
    DrawFormattedText(winPartner, confirmTextPartner, 'center', 'center', white, [], [], [], 1.2);

    markerValue = 11;
    setVpixxMarker(winEEG, markerValue); setVpixxMarker(winPartner, markerValue);
    flipTimeEEG = Screen('Flip', winEEG);
    flipTimePartner = Screen('Flip', winPartner);
    VpixxMarkerZero(winEEG); VpixxMarkerZero(winPartner);
    triggerLog(end+1,:) = [markerValue, flipTimeEEG, flipTimePartner];

    KbWait([], 2);  % wait any key to continue

    %% ------------------- Price Choice (EEG) ; Partner sees another message -------------------
    prices = priceOptions{chosenObj};
    nOptions = numel(prices);

    % draw EEG: picture (larger) + two text options
    % prepare image if exists
    priceImgPath = imagePaths{chosenObj};
    thumbTex = 0; imgW=0; imgH=0;
    if ~isempty(priceImgPath) && exist(priceImgPath,'file')
        tmp = imread(priceImgPath);
        if size(tmp,3)==1, tmp = repmat(tmp,[1 1 3]); end
        [h0,w0,~] = size(tmp);
        maxW = round(winRectEEG(3)*0.8);
        maxH = round(winRectEEG(4)*0.45);
        scale = min(maxW/w0, maxH/h0); scale = min(scale,1);
        newW = max(1, round(w0*scale)); newH = max(1, round(h0*scale));
        imgResized = imresize(tmp, [newH newW]);
        thumbTex = Screen('MakeTexture', winEEG, imgResized);
        imgW = newW; imgH = newH;
    end

    % EEG draw
    Screen('FillRect', winEEG, black);
    centerX = round(winRectEEG(3)/2);
    imgCenterY = round(winRectEEG(4)*0.26);
    if thumbTex ~= 0
        imgRect = [centerX-imgW/2, imgCenterY-imgH/2, centerX+imgW/2, imgCenterY+imgH/2];
        Screen('DrawTexture', winEEG, thumbTex, [], imgRect);
    else
        placeholderW = min(round(winRectEEG(3)*0.6), 600);
        placeholderH = min(round(winRectEEG(4)*0.35), 400);
        imgRect = [centerX-placeholderW/2, imgCenterY-placeholderH/2, centerX+placeholderW/2, imgCenterY+placeholderH/2];
        Screen('FrameRect', winEEG, white, imgRect, 3);
        DrawFormattedText(winEEG, 'Kein Bild vorhanden', imgRect(1)+10, imgRect(2)+10, white);
    end
    Screen('TextSize', winEEG, 26);
    DrawFormattedText(winEEG, sprintf('%s\n\n%s', objects{chosenObj}, descriptions{chosenObj}), 'center', imgRect(4)+10, white, 70, [], [], 1.2);
    Screen('TextSize', winEEG, 24);

    % draw options
    lineSpacing = round(winRectEEG(4) * 0.08);
    optYs = round(winRectEEG(4)*0.35) + (0:(nOptions-1))*lineSpacing;
    for i = 1:nOptions
        DrawFormattedText(winEEG, prices{i}, 'center', optYs(i)-12, white);
    end

    % partner screen: different content
    DrawFormattedText(winPartner, 'Partner: Beobachte die Entscheidung des EEG-Teilnehmers...', 'center', 'center', white);

    % marker+flip both
    markerValue = 20;
    setVpixxMarker(winEEG, markerValue); setVpixxMarker(winPartner, markerValue);
    flipTimeEEG = Screen('Flip', winEEG);
    flipTimePartner = Screen('Flip', winPartner);
    VpixxMarkerZero(winEEG); VpixxMarkerZero(winPartner);
    triggerLog(end+1,:) = [markerValue, flipTimeEEG, flipTimePartner];

    % wait for key 1 or 2
    chosenPriceIdx = NaN;
    while isnan(chosenPriceIdx)
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            key = KbName(keyCode);
            if iscell(key), key = key{1}; end
            key = key(1); % take first character
            if strcmp(key,'1'), chosenPriceIdx = 1; RT_price = GetSecs - flipTimeEEG; break; end
            if strcmp(key,'2'), chosenPriceIdx = 2; RT_price = GetSecs - flipTimeEEG; break; end
        end
        WaitSecs(0.01);
    end
    chosenPrice = prices{chosenPriceIdx};

    if thumbTex ~= 0, Screen('Close', thumbTex); end

    %% ------------------- Final Selection (EEG) + Partner message -------------------
    Screen('FillRect', winEEG, black);
    if exist(imagePaths{chosenObj}, 'file')
        finalImg = imread(imagePaths{chosenObj});
        if size(finalImg,3)==1, finalImg = repmat(finalImg,[1 1 3]); end
        maxW = round(winRectEEG(3)*0.6);
        maxH = round(winRectEEG(4)*0.4);
        [h0,w0,~] = size(finalImg);
        scale = min(maxW/w0, maxH/h0); scale = min(scale,1);
        newW = max(1,round(w0*scale)); newH = max(1,round(h0*scale));
        finalImg = imresize(finalImg,[newH newW]);
        finalTex = Screen('MakeTexture', winEEG, finalImg);
        imgRectFinal = CenterRectOnPoint([0 0 newW newH], winRectEEG(3)/2, winRectEEG(4)*0.3);
        Screen('DrawTexture', winEEG, finalTex, [], imgRectFinal);
    else
        finalTex = 0;
    end

    Screen('TextSize', winEEG, 26);
    finalText = sprintf('Final selection:\n\nObject: %s\nPrice: %s\n\nIn the next part, your partner will ask you questions.', objects{chosenObj}, chosenPrice);
    DrawFormattedText(winEEG, finalText, 'center', winRectEEG(4)*0.55, white, 70, [], [], 1.2);

    DrawFormattedText(winPartner, 'Partner: Bitte bereite deine Fragen vor.', 'center', 'center', white);

    markerValue = 30;
    setVpixxMarker(winEEG, markerValue); setVpixxMarker(winPartner, markerValue);
    flipTimeEEG = Screen('Flip', winEEG);
    flipTimePartner = Screen('Flip', winPartner);
    VpixxMarkerZero(winEEG); VpixxMarkerZero(winPartner);
    triggerLog(end+1,:) = [markerValue, flipTimeEEG, flipTimePartner];

    KbWait([], 2);
    if finalTex ~= 0, Screen('Close', finalTex); end

%% ------------------- Fragebogen (EEG sees questions; Partner selects with mouse) -------------------

% load questions from Excel
questionTable = readtable('questions.xlsx');
questions = questionTable.Question;

    
nRounds = 3; % Anzahl Runden
rng('shuffle'); 
questionsAvailable = questions(randperm(length(questions))); % zufällige Reihenfolge
questionResponses = cell(nRounds,1);

for roundIdx = 1:nRounds
    % --- Partner wählt 3 Fragen ---
    if length(questionsAvailable) < 3
        questionPool = questionsAvailable;
    else
        questionPool = questionsAvailable(1:3);
    end
    
    selectedIdx = NaN;
    tPartnerStart = GetSecs;  % Startzeit für Partner-RT
    while isnan(selectedIdx)
        Screen('FillRect', winPartner, black);
        buttonRects = cell(1,3);
        for i = 1:length(questionPool)
            btnW = 500; btnH = 80;
            btnRect = CenterRectOnPoint([0 0 btnW btnH], winRectPartner(3)/2, 200 + (i-1)*(btnH+20));
            Screen('FillRect', winPartner, [80 80 80], btnRect);
            DrawFormattedText(winPartner, questionPool{i}, 'center', btnRect(2)+20, white, [], [], [], 1.2);
            buttonRects{i} = btnRect;
        end
        flipTimePartner = Screen('Flip', winPartner);
        ShowCursor(partnerScreenNumber); 
        HideCursor(eegScreenNumber);
        
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
    selectedQuestion = questionPool{selectedIdx};
    Screen('FillRect', winEEG, black);
    DrawFormattedText(winEEG, selectedQuestion, 'center', 'center', white, [], [], [], 1.5);

    markerValue = 40 + roundIdx; % Marker
    setVpixxMarker(winEEG, markerValue);
    setVpixxMarker(winPartner, markerValue);
    flipTimeEEG = Screen('Flip', winEEG);
    flipTimePartner = Screen('Flip', winPartner);
    VpixxMarkerZero(winEEG); VpixxMarkerZero(winPartner);
    triggerLog(end+1,:) = [markerValue, flipTimeEEG, flipTimePartner];
    
    % --- EEG-Person antwortet ---
    eegAnswer = NaN;
    tEEGStart = GetSecs;  % Startzeit EEG
    while isnan(eegAnswer)
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            key = KbName(keyCode);
            if iscell(key), key = key{1}; end
            if strcmpi(key,'LeftArrow'), eegAnswer = 'Ja'; end
            if strcmpi(key,'RightArrow'), eegAnswer = 'Nein'; end
        end
        WaitSecs(0.01);
    end
    RT_EEG = GetSecs - tEEGStart;  % EEG RT speichern

    Screen('FillRect', winPartner, black);
    DrawFormattedText(winPartner, sprintf('EEG-Antwort:\n%s', eegAnswer), 'center', 'center', white);
    Screen('Flip', winPartner);
    WaitSecs(1.5);
    
    % --- Loggen ---
    questionResponses{roundIdx} = struct('question', selectedQuestion, ...
                                        'response', eegAnswer, ...
                                        'RT', RT_EEG, ...
                                        'RT_partner', RT_partner);
    
    % Entferne gewählte Frage aus dem Pool
    questionsAvailable(strcmp(questionsAvailable, selectedQuestion)) = [];
end

%% --- Abschlussfrage Partner ---
Screen('FillRect', winPartner, black);
ShowCursor('Arrow', partnerScreenNumber);
finalText = ['Du hast viele Fragen gestellt und dir hoffentlich eine Meinung gebildet, ', ...
    'ob das Angebot ein guter Deal ist, oder ob dich der Verkäufer über den Tisch ziehen möchte.\n\n', ...
    'Möchtest du das Angebot vom Verkäufer annehmen?'];
DrawFormattedText(winPartner, finalText, 'center', 50, white, [], [], [], 1.2);

% Buttons "Ja" / "Nein"
buttonW = 300; buttonH = 80;
yesRect = CenterRectOnPoint([0 0 buttonW buttonH], winRectPartner(3)/3, winRectPartner(4)*0.7);
noRect  = CenterRectOnPoint([0 0 buttonW buttonH], 2*winRectPartner(3)/3, winRectPartner(4)*0.7);
Screen('FillRect', winPartner, [80 180 80], yesRect);
Screen('FillRect', winPartner, [180 80 80], noRect);
DrawFormattedText(winPartner, 'Ja', 'center', 'center', white, [], [], [], 1.2, [], yesRect);
DrawFormattedText(winPartner, 'Nein', 'center', 'center', white, [], [], [], 1.2, [], noRect);

Screen('Flip', winPartner);

tStartAngebot = GetSecs;  % Startzeit finale Partner-Entscheidung
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
RT_finalPartner = GetSecs - tStartAngebot;  % RT finale Entscheidung

Screen('FillRect', winEEG, black);
DrawFormattedText(winEEG, sprintf('Die Entscheidung des Partners: %s', finalResp), 'center', 'center', white, [], [], [], 1.2);
Screen('Flip', winEEG);
WaitSecs(1.0);


    end
    %% ------------------- Save Data pro Frage -------------------
for block = 1:nBlocks
    nQuestions = numel(questionResponses);
    for q = 1:nQuestions
        newRow = table;
        newRow.subject         = {vpID};
        newRow.block           = block;
        newRow.chosenObject    = {objects{chosenObj}};
        newRow.imageChoiceRT   = RT_imageChoice;
        newRow.chosenPrice     = {chosenPrice};
        newRow.priceRT         = RT_price;
        newRow.question        = {questionResponses{q}.question};
        newRow.questionAnswer  = {questionResponses{q}.response};
        newRow.RT_EEG          = questionResponses{q}.RT;          % EEG-Reaktionszeit
        newRow.RT_Partner      = questionResponses{q}.RT_partner;  % Partner-Reaktionszeit beim Fragen wählen
        newRow.angebotAnnehmen = {finalResp};
        newRow.RT_Angebot      = RT_finalPartner;                  % Partner RT bei finaler Entscheidung
        newRow.triggerLog      = {jsonencode(triggerLog)};

        dataTable = [dataTable; newRow];
    end
end

    %% --- speichern ---
    saveFile = sprintf('response_%s_%s.xlsx', vpID, datestr(now,'yyyymmdd_HHMMSS'));
    writetable(dataTable, saveFile);
    fprintf('Daten gespeichert in %s\n', saveFile);

    ShowCursor;
    Screen('CloseAll');

catch ME
    ShowCursor;
    Screen('CloseAll');
    rethrow(ME);
end
