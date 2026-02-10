%% cars_messages_dualScreen_FINAL.m
Screen('Preference','SkipSyncTests',1);
KbName('UnifyKeyNames');
Priority(MaxPriority('GetSecs'));

%% ================= SETTINGS =================
nBlocks           = 2;  
questionsPerBlock = 2;    


%% ================= VP-ID =================
answer = inputdlg({'VP-ID:'},'VP',[1 40],{'demo'});
if isempty(answer), error('Abbruch'); end
vpID = answer{1};

%% ================= SCREENS =================
screens = Screen('Screens');
eegScreen     = 1;
partnerScreen = max(screens);

black = BlackIndex(eegScreen);
white = WhiteIndex(eegScreen);

[winEEG, rectEEG]         = Screen('OpenWindow', eegScreen, black);
[winPartner, rectPartner] = Screen('OpenWindow', partnerScreen, black);

HideCursor(eegScreen);
ShowCursor(partnerScreen);

%% ================= WAIT ICON =================
waitIconImg = imread('wait_message.png');
if size(waitIconImg,3)==1
    waitIconImg = repmat(waitIconImg,[1 1 3]);
end

waitIconTexEEG     = Screen('MakeTexture', winEEG, waitIconImg);
waitIconTexPartner = Screen('MakeTexture', winPartner, waitIconImg);

iconScale = 0.25;
[h,w,~] = size(waitIconImg);

waitIconRectEEG = CenterRectOnPointd([0 0 w*iconScale h*iconScale], ...
    rectEEG(3)/2, rectEEG(4)/2);
waitIconRectPartner = CenterRectOnPointd([0 0 w*iconScale h*iconScale], ...
    rectPartner(3)/2, rectPartner(4)/2);

%% ================= TEXT STYLE =================
Screen('TextFont', winEEG, 'Verdana');
Screen('TextFont', winPartner, 'Verdana');
Screen('TextSize', winEEG, 40);
Screen('TextSize', winPartner, 40);

%% ================= ViewPixxmarker initialisierung =================
topLeftPixel = [0 0 1 1];
VpixxMarkerZero = @(win) Screen('FillRect', win, [0 0 0], topLeftPixel);
setVpixxMarker  = @(win,val) Screen('FillRect', win, [val 0 0], topLeftPixel);

VpixxMarkerZero(winEEG);
VpixxMarkerZero(winPartner);
Screen('Flip', winEEG);
Screen('Flip', winPartner);

% Trigger-Log initialisieren
triggerLog = [];
questionResponses = {};


%% ================= LOAD EXCEL =================
stim      = readtable('stimuli_car.xlsx');
questions = readtable('questions_car.xlsx');

stim = stim(randperm(height(stim)), :); %trial randomisieren


questions_specific = questions(strcmp(questions.Type,'specific'),:);
questions_general  = questions(strcmp(questions.Type,'general'),:);

%Fragen randomisieren 
questions_specific = questions_specific(randperm(height(questions_specific)), :);
questions_general  = questions_general(randperm(height(questions_general)), :);

data = table();

nTrials = min(nBlocks, height(stim));

%% ================= TRIAL LOOP =================
for t = 1:nTrials

    riskFlag = lower(string(stim.Risk{t}));


    %% ---------- LOAD IMAGES ----------
    texL = 0; texR = 0;
    if exist(stim.Image_L{t},'file')
        img = imread(stim.Image_L{t});
        if size(img,3)==1, img=repmat(img,[1 1 3]); end
        texL = Screen('MakeTexture',winEEG,img);
    end
    if exist(stim.Image_R{t},'file')
        img = imread(stim.Image_R{t});
        if size(img,3)==1, img=repmat(img,[1 1 3]); end
        texR = Screen('MakeTexture',winEEG,img);
    end

%% ---------- EEG MESSAGE SELECTION ----------
Screen('FillRect', winEEG, black);

%---------- RISIKO-ANZEIGE (NUR EEG) ----------
if riskFlag == "ja"
    riskText = 'RISIKO: JA\nDer Käufer sieht Zusatzinformationen';
else
    riskText = 'RISIKO: NEIN\nDer Käufer sieht keine Zusatzinformationen';
end

DrawFormattedText(winEEG, riskText, ...
    'center', rectEEG(4)*0.14, white, [], [], [], 1.2);

% ---------- POSITIONEN ----------
cx   = rectEEG(3)/2;
xOff = rectEEG(3)*0.25;

% ---------- TITEL ----------
DrawFormattedText(winEEG, 'Angebot A', ...
    cx-xOff, 'center', white, [], [], [], [], [], ...
    [cx-xOff-200 40 cx-xOff+200 90]);

DrawFormattedText(winEEG, 'Angebot B', ...
    cx+xOff, 'center', white, [], [], [], [], [], ...
    [cx+xOff-200 40 cx+xOff+200 90]);

% ---------- BILDER ----------
imgRectL = CenterRectOnPoint([0 0 420 260], cx-xOff, rectEEG(4)*0.28);
imgRectR = CenterRectOnPoint([0 0 420 260], cx+xOff, rectEEG(4)*0.28);

if texL ~= 0
    Screen('DrawTexture', winEEG, texL, [], imgRectL);
end
if texR ~= 0
    Screen('DrawTexture', winEEG, texR, [], imgRectR);
end

% ---------- PREIS / WERT ----------
DrawFormattedText(winEEG, ...
    sprintf('Preis: %d €\nWert: %d €', stim.Price_L(t), stim.Value_L(t)), ...
    cx-xOff-150, rectEEG(4)*0.48, white);

DrawFormattedText(winEEG, ...
    sprintf('Preis: %d €\nWert: %d €', stim.Price_R(t), stim.Value_R(t)), ...
    cx+xOff-150, rectEEG(4)*0.48, white);

% ---------- TRENNLINIE ----------
Screen('DrawLine', winEEG, white, ...
    rectEEG(3)*0.1, rectEEG(4)*0.58, ...
    rectEEG(3)*0.9, rectEEG(4)*0.58, 3);

% ---------- MESSAGES ----------
DrawFormattedText(winEEG, ...
    ['NACHRICHT:\n\n' stim.Message_L{t}], ...
    cx-xOff-250, rectEEG(4)*0.63, white, 60);

DrawFormattedText(winEEG, ...
    ['NACHRICHT:\n\n' stim.Message_R{t}], ...
    cx+xOff-250, rectEEG(4)*0.63, white, 60);

% ---------- FLIP ----------
markerValue = 33;  % Angebot erscheint
setVpixxMarker(winEEG, markerValue);

tFlip = Screen('Flip', winEEG);

VpixxMarkerZero(winEEG);
triggerLog(end+1,:) = [markerValue, tFlip];



% ---------- EEG WAHL ----------
chosenSide = '';
while isempty(chosenSide)
    [~,~,kc] = KbCheck;
    if kc(KbName('LeftArrow'))
        chosenSide = 'L';
    elseif kc(KbName('RightArrow'))
        chosenSide = 'R';
    end
end

RT_choice = GetSecs - tFlip;

markerValue = 33;  
setVpixxMarker(winEEG, markerValue);
tResp = GetSecs;
VpixxMarkerZero(winEEG);

triggerLog(end+1,:) = [markerValue, tResp];



%% ---------- OFFER DATA ----------
if chosenSide == 'L'
    message      = stim.Message_L{t};
    infoTextRaw  = char(stim.InfoText_L(t));
    infoCodesRaw = char(stim.InfoCode_L(t));

    Value_chosen = stim.Value_L(t);
    Price_chosen = stim.Price_L(t);
    Value_other  = stim.Value_R(t);
    Price_other  = stim.Price_R(t);
else
    message      = stim.Message_R{t};
    infoTextRaw  = char(stim.InfoText_R(t));
    infoCodesRaw = char(stim.InfoCode_R(t));

    Value_chosen = stim.Value_R(t);
    Price_chosen = stim.Price_R(t);
    Value_other  = stim.Value_L(t);
    Price_other  = stim.Price_L(t);
end


    buyerGain_chosen=Value_chosen-Price_chosen;
    buyerGain_other =Value_other -Price_other;
    honesty=string(buyerGain_chosen>=buyerGain_other);
    honesty(honesty=="1")="ehrlich";
    honesty(honesty=="0")="gelogen";

    riskFlag=lower(string(stim.Risk(t)));

    infoDisplay='';
    if ~isempty(infoTextRaw)
        parts=strtrim(strsplit(infoTextRaw,';'));
        for i=1:numel(parts)
            infoDisplay=[infoDisplay,'• ',parts{i},newline];
        end
    end

    %% ---------- PARTNER SUMMARY ----------
    eegOK=false; partnerOK=false;
    confirmBtn=CenterRectOnPoint([0 0 300 90],rectPartner(3)/2,rectPartner(4)*0.88);

%% ---------- EEG ANGEBOTSÜBERSICHT ----------
Screen('FillRect', winEEG, black);

cxE   = rectEEG(3)/2;
xOffE = rectEEG(3)*0.25;

DrawFormattedText(winEEG, 'Angebotsübersicht', 'center', 40, white);

% ----- Bilder -----
imgRectEL = CenterRectOnPoint([0 0 420 260], cxE-xOffE, rectEEG(4)*0.30);
imgRectER = CenterRectOnPoint([0 0 420 260], cxE+xOffE, rectEEG(4)*0.30);

if texL~=0, Screen('DrawTexture',winEEG,texL,[],imgRectEL); end
if texR~=0, Screen('DrawTexture',winEEG,texR,[],imgRectER); end

% ----- Preise -----
DrawFormattedText(winEEG, ...
    sprintf('Preis: %d €', stim.Price_L(t)), ...
    cxE-xOffE-120, imgRectEL(4)+10, white);

DrawFormattedText(winEEG, ...
    sprintf('Preis: %d €', stim.Price_R(t)), ...
    cxE+xOffE-120, imgRectER(4)+10, white);

% ----- Trennlinie -----
Screen('DrawLine', winEEG, white, ...
    rectEEG(3)*0.1, rectEEG(4)*0.55, ...
    rectEEG(3)*0.9, rectEEG(4)*0.55, 3);

% ----- Empfehlung -----
DrawFormattedText(winEEG, ...
    sprintf('Der Verkäufer schreibt:\n\n"%s"', message), ...
    'center', rectEEG(4)*0.60, white, 70);

% ----- Zusatzinfos (EEG IMMER) -----
if ~isempty(infoDisplay)
    DrawFormattedText(winEEG, ...
        ['Zusätzliche Informationen:\n' infoDisplay], ...
        'center', rectEEG(4)*0.75, white, 70);
end

DrawFormattedText(winEEG, ...
    'Drücke LEERTASTE, um fortzufahren', ...
    'center', rectEEG(4)*0.90, white);

% Marker
markerValue = 33;  
setVpixxMarker(winEEG, markerValue);

tFlipOverview = Screen('Flip', winEEG);

VpixxMarkerZero(winEEG);

triggerLog(end+1,:) = [markerValue, tFlipOverview];



    Screen('FillRect',winPartner,black);
    cxP=rectPartner(3)/2; xOffP=rectPartner(3)*0.25;

    DrawFormattedText(winPartner,'Angebotsübersicht','center',40,white);

    imgRectPL=CenterRectOnPoint([0 0 420 260],cxP-xOffP,rectPartner(4)*0.30);
    imgRectPR=CenterRectOnPoint([0 0 420 260],cxP+xOffP,rectPartner(4)*0.30);

    if texL~=0, Screen('DrawTexture',winPartner,texL,[],imgRectPL); end
    if texR~=0, Screen('DrawTexture',winPartner,texR,[],imgRectPR); end

    DrawFormattedText(winPartner,sprintf('Preis: %d €',stim.Price_L(t)),cxP-xOffP-120,imgRectPL(4)+10,white);
    DrawFormattedText(winPartner,sprintf('Preis: %d €',stim.Price_R(t)),cxP+xOffP-120,imgRectPR(4)+10,white);

    Screen('DrawLine',winPartner,white,rectPartner(3)*0.1,rectPartner(4)*0.55,rectPartner(3)*0.9,rectPartner(4)*0.55,3);

    DrawFormattedText(winPartner,sprintf('Der Verkäufer schreibt:\n\n"%s"',message), ...
        'center',rectPartner(4)*0.60,white,70);

    if riskFlag=="ja"
        DrawFormattedText(winPartner,['Zusätzliche Informationen:\n',infoDisplay], ...
            'center',rectPartner(4)*0.75,white,70);
    end

    Screen('FillRect',winPartner,[80 80 80],confirmBtn);
    DrawFormattedText(winPartner,'Weiter','center','center',white,[],[],[],[],[],confirmBtn);
    Screen('Flip',winPartner);

    while ~(eegOK && partnerOK)
        [kd,~,kc]=KbCheck;
        if kd && kc(KbName('space')), eegOK=true; end
        [mx,my,b]=GetMouse(partnerScreen);
        if any(b) && IsInRect(mx,my,confirmBtn), partnerOK=true; end
        WaitSecs(0.01);
    end

%% ---------- QUESTION POOLS ----------
if isempty(infoCodesRaw)
    infoCodes = strings(0);
else
    infoCodes = string(strtrim(strsplit(infoCodesRaw, ';')));
end


questions_specific.Code = string(questions_specific.Code);

specificPool = questions_specific( ...
    ismember(questions_specific.Code, infoCodes), :);

generalPool = questions_general;


%% ---------- QUESTIONNAIRE ----------
for r = 1:questionsPerBlock


    % ---------- Fragenset + Herkunft ----------
    questionSet    = {};
    questionSource = {};  

    % --- 1 spezifische Frage ---
    if height(specificPool) > 0
        questionSet{end+1}    = specificPool.Question{1};
        questionSource{end+1} = 'specific';
    end

    % --- mit allgemeinen Fragen auffüllen ---
    nGen = min(3 - numel(questionSet), height(generalPool));
    for i = 1:nGen
        questionSet{end+1}    = generalPool.Question{i};
        questionSource{end+1} = 'general';
    end

    % --- gemeinsam mischen ---
    perm = randperm(numel(questionSet));
    questionSet    = questionSet(perm);
    questionSource = questionSource(perm);

    % ---------- Partner wählt Frage ----------
    selectedIdx = NaN;
    while isnan(selectedIdx)

        Screen('FillRect', winPartner, black);
        rects = cell(1, numel(questionSet));

        for i = 1:numel(questionSet)
            rects{i} = CenterRectOnPoint( ...
                [0 0 700 90], ...
                rectPartner(3)/2, ...
                rectPartner(4)*(0.3 + 0.15*i) );
            Screen('FillRect', winPartner, [80 80 80], rects{i});
            DrawFormattedText(winPartner, questionSet{i}, ...
                'center', 'center', white, [], [], [], [], [], rects{i});
        end
        Screen('Flip', winPartner);

        Screen('FillRect', winEEG, black);
        Screen('DrawTexture', winEEG, waitIconTexEEG, [], waitIconRectEEG);
        Screen('Flip', winEEG);

        [mx, my, buttons] = GetMouse(partnerScreen);
        if any(buttons)
            for i = 1:numel(rects)
                if IsInRect(mx, my, rects{i})
                    selectedIdx = i;
                end
            end
        end
    end

    selectedQuestion = questionSet{selectedIdx};
    selectedSource   = questionSource{selectedIdx};

    % ---------- EEG sieht Frage ----------
Screen('FillRect', winEEG, black);
DrawFormattedText(winEEG, selectedQuestion, ...
    'center', 'center', white);

% marker
markerValue = 33;  
setVpixxMarker(winEEG, markerValue);

tFlipQuestion = Screen('Flip', winEEG);

VpixxMarkerZero(winEEG);
triggerLog(end+1,:) = [markerValue, tFlipQuestion];


    % ---------- EEG antwortet ----------
    eegAnswer = '';
    while isempty(eegAnswer)

        Screen('FillRect', winPartner, black);
        Screen('DrawTexture', winPartner, waitIconTexPartner, [], waitIconRectPartner);
        Screen('Flip', winPartner);

        [~,~,kc] = KbCheck;
        if kc(KbName('LeftArrow'))
            eegAnswer = 'Ja';
            markerValue = 33;   
            setVpixxMarker(winEEG, markerValue);
            tResp = GetSecs;
            VpixxMarkerZero(winEEG);
            triggerLog(end+1,:) = [markerValue, tResp];
        end

        if kc(KbName('RightArrow'))
            eegAnswer = 'Nein';
            markerValue = 33;  
            setVpixxMarker(winEEG, markerValue);
            tResp = GetSecs;
            VpixxMarkerZero(winEEG);
            triggerLog(end+1,:) = [markerValue, tResp];
        end

        qr.question     = selectedQuestion;
        qr.response     = eegAnswer;
        qr.RT_EEG       = tResp - tFlipQuestion;   
        qr.RT_Partner   = NaN;                      
        questionResponses{end+1} = qr;


    end

    % ---------- Partner sieht Antwort ----------
    Screen('FillRect', winPartner, black);
    DrawFormattedText(winPartner, ['Antwort:\n\n', eegAnswer], ...
        'center', 'center', white);
    Screen('Flip', winPartner);

    Screen('FillRect', winEEG, black);
    Screen('DrawTexture', winEEG, waitIconTexEEG, [], waitIconRectEEG);
    Screen('Flip', winEEG);
    WaitSecs(1);

    % ---------- Frage endgültig aus Pool entfernen ----------
    if strcmp(selectedSource, 'specific')
        specificPool(1,:) = [];
    else
        generalPool(strcmp(generalPool.Question, selectedQuestion), :) = [];
    end

end


%% ---------- PARTNER: ANGEBOTSAUSWAHL (A / B) ----------
Screen('FillRect', winPartner, black);

cxP   = rectPartner(3)/2;
xOffP = rectPartner(3)*0.25;

% ---------- Titel ----------
DrawFormattedText(winPartner, ...
    'Welches Angebot möchtest du annehmen?', ...
    'center', rectPartner(4)*0.08, white);

% ---------- Bilder ----------
imgY = rectPartner(4)*0.30;

imgRectPL = CenterRectOnPoint([0 0 420 260], cxP-xOffP, imgY);
imgRectPR = CenterRectOnPoint([0 0 420 260], cxP+xOffP, imgY);

if texL~=0, Screen('DrawTexture', winPartner, texL, [], imgRectPL); end
if texR~=0, Screen('DrawTexture', winPartner, texR, [], imgRectPR); end

% ---------- Labels ----------
DrawFormattedText(winPartner,'Angebot A', ...
    cxP-xOffP,'center',white,[],[],[],[],[], ...
    [cxP-xOffP-200 rectPartner(4)*0.18 cxP-xOffP+200 rectPartner(4)*0.23]);

DrawFormattedText(winPartner,'Angebot B', ...
    cxP+xOffP,'center',white,[],[],[],[],[], ...
    [cxP+xOffP-200 rectPartner(4)*0.18 cxP+xOffP+200 rectPartner(4)*0.23]);

% ---------- Preise ----------
DrawFormattedText(winPartner, ...
    sprintf('Preis: %d €', stim.Price_L(t)), ...
    cxP-xOffP-120, imgRectPL(4)+15, white);

DrawFormattedText(winPartner, ...
    sprintf('Preis: %d €', stim.Price_R(t)), ...
    cxP+xOffP-120, imgRectPR(4)+15, white);

% ---------- Trennlinie ----------
Screen('DrawLine', winPartner, white, ...
    rectPartner(3)*0.1, rectPartner(4)*0.55, ...
    rectPartner(3)*0.9, rectPartner(4)*0.55, 3);

% ---------- EEG-Empfehlung ----------
DrawFormattedText(winPartner, ...
    sprintf('Der Verkäufer empfiehlt:\n\n"%s"', message), ...
    'center', rectPartner(4)*0.60, white, 70);

% ---------- Buttons A / B ----------
buttonW = 260; buttonH = 90;

btnA = CenterRectOnPoint([0 0 buttonW buttonH], ...
    cxP-xOffP, rectPartner(4)*0.82);

btnB = CenterRectOnPoint([0 0 buttonW buttonH], ...
    cxP+xOffP, rectPartner(4)*0.82);

Screen('FillRect', winPartner, [80 80 80], btnA);
Screen('FillRect', winPartner, [80 80 80], btnB);

DrawFormattedText(winPartner, 'A', ...
    'center','center',white,[],[],[],[],[],btnA);
DrawFormattedText(winPartner, 'B', ...
    'center','center',white,[],[],[],[],[],btnB);

Screen('Flip', winPartner);

%% ---------- EEG: WARTETEXT ----------
Screen('FillRect', winEEG, black);
DrawFormattedText(winEEG, ...
    'Der Käufer entscheidet gerade …', ...
    'center','center',white);
Screen('Flip', winEEG);

%% ---------- MAUSABFRAGE PARTNER ----------
finalChoice = '';
while isempty(finalChoice)

    [mx,my,buttons] = GetMouse(partnerScreen);
    if any(buttons)
        if IsInRect(mx,my,btnA)
            finalChoice = 'A';
        elseif IsInRect(mx,my,btnB)
            finalChoice = 'B';
        end
        WaitSecs(0.2); 
    end
    WaitSecs(0.01);
end


    %% ---------- LOG ----------
    nQuestions = numel(questionResponses);

    for q = 1:nQuestions
        newRow = table;

        newRow.subject        = {vpID};
        newRow.trial          = t;

        % Angebotswahl EEG
        newRow.choiceEEG      = {chosenSide};
        newRow.RT_choiceEEG   = RT_choice;

        % Frage
        newRow.question       = {questionResponses{q}.question};
        newRow.questionAnswer = {questionResponses{q}.response};
        newRow.RT_EEG         = questionResponses{q}.RT_EEG;

        % Partner Entscheidung
        newRow.finalChoice    = {finalChoice};

        % Meta
        newRow.risk           = {riskFlag};
        newRow.honesty        = {honesty};

        % Trigger
        newRow.triggerLog     = {jsonencode(triggerLog)};

        data = [data; newRow];
    end

end

%% ================= SAVE & CLEANUP =================
ts = datestr(now,'yyyymmdd_HHMMSS');

% Dateinamen
fileCSV  = sprintf('cars_messages_%s_%s.csv',  vpID, ts);
fileXLSX = sprintf('cars_messages_%s_%s.xlsx', vpID, ts);
fileMAT  = sprintf('cars_messages_%s_%s.mat',  vpID, ts);

% Speichern
writetable(data, fileCSV);
writetable(data, fileXLSX);
save(fileMAT, 'data');

Screen('Close',waitIconTexEEG);
Screen('Close',waitIconTexPartner);
ShowCursor;
Screen('CloseAll');
Priority(0);
