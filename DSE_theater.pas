unit DSE_theater;
//{$Define nagscreen}
{$Define Angle} { TODO : verificare eventuali bug  }
interface

uses
  Windows, Messages, vcl.Graphics, vcl.Controls, vcl.Forms, system.Classes, system.SysUtils, vcl.StdCtrls, vcl.ExtCtrls, strutils,DSE_list,
  DSE_Bitmap, DSE_ThreadTimer, DSE_Misc, DSE_defs,  Generics.Collections ,Generics.Defaults, dse_pathplanner;

  Type TGridStyle = (gsNone,gsHex);
  Type TRenderBitmap = ( VirtualRender, VisibleRender );
type
  SE_Theater = class;
  SE_Engine =  class;
  SE_Sprite = class;


  SE_TheaterEvent = procedure( Sender: TObject; VirtualBitmap, VisibleBitmap: SE_Bitmap ) of object;
  TCollisionEvent = procedure( Sender: TObject; Sprite1, Sprite2: SE_Sprite ) of object;

  SE_EngineEvent = procedure(  ASprite: SE_Sprite ) of object;

  SE_GridMouseEvent = procedure( Sender: TObject;  Button: TMouseButton; Shift: TShiftState; CellX, CellY: integer) of object;
  SE_GridMouseMoveEvent = procedure( Sender: TObject; Shift: TShiftState; CellX, CellY: integer ) of object;

  SE_SpriteEvent = procedure( Sender: TObject; ASprite: SE_Sprite ) of object;
  SE_SpriteEventDstReached = procedure of object;

  SE_SpriteMouseEvent = procedure( Sender: TObject; lstSprite: TObjectList<SE_Sprite>; Button: TMouseButton; Shift: TShiftState  ) of object;
  SE_SpriteMouseMoveEvent = procedure( Sender: TObject; lstSprite: TObjectList<SE_Sprite>; Shift: TShiftState; var Handled: boolean) of object;

  SE_TheaterMouseEvent = procedure( Sender: TObject; VisibleX,VisibleY,VirtualX,VirtualY: integer; Button: TMouseButton;Shift: TShiftState ) of object;
  SE_TheaterMouseMoveEvent = procedure( Sender: TObject; VisibleX,VisibleY,VirtualX,VirtualY: integer; Shift: TShiftState ) of object;

  SE_SubSprite = class (Tobject)
  private
  protected
  public
    lBmp: SE_Bitmap;
    lTransparent: boolean;
    lX : Integer;
    lY : Integer;
    lVisible: Boolean;
    Guid: string;
    stag: string;
    LifeSpan: Integer;
    dead: Boolean;
  constructor create (bmpFilename,Guid:string; x,y: integer;  visible,Transparent: boolean);overload;
  constructor create (bmp:SE_Bitmap; Guid:string;x,y: integer; visible,Transparent: boolean);overload;
  destructor Destroy;override;
  end;


  SE_SpriteLabel = class (Tobject)
  private
  protected
  public
    Transparent: boolean; // riguardo a lbmp ma al momento non usato singolarmente
    lX : Integer;
    lY : Integer;
    lFont: TFont;
    lText : String;
    lpenMode: TPenMode;
    lVisible: Boolean;
    lBackColor: TColor;
    itag: integer;
    stag: string;
    LifeSpan: Integer;
    Dead: boolean;
  constructor create (x,y: integer; FontName: string; FontColor, BackColor: TColor; atext: string;aPenMode: TPenMode; visible: boolean);
  destructor Destroy;override;
  end;

  SE_Theater = class(TCustomControl)
  private

    iCollisionDelay: Integer;
    fCollisionDelay: Integer;
    fBackColor: TColor;

    fVisibleBitmap: SE_Bitmap;
    fVirtualBitmap: SE_Bitmap;

    fMousePan: boolean;
    fMouseScroll: boolean;
    fMouseScrollRate: Double;
    fMouseWheelInvert: boolean;
    fMouseWheelValue: integer;
    fMouseWheelZoom: boolean;

    MouseDownViewX, MouseDownViewY: integer;

    VirtualSource1x, VirtualSource1y, VirtualSourceWidth, VirtualSourceHeight: integer;
    fDstX, fDstY: integer;

    fVirtualWidth: integer;
    fVirtualheight: integer;

    FActive: boolean;

    // Grid
    FGridVisible:boolean;
    FGridInfoCell : boolean;
    FGrid:TGridStyle;
    FGridColor:TColor;
    FCellsX: integer;
    FCellsY: integer;
    FCellHeight: integer;  // solo square
    FCellwidth: integer;   // solo square
    AHexCellSize: THexCellSize; // solo Hex

    fHexSmallwidth: integer;

    // mouse
    FOnMouseUp: TMouseEvent;
    FOnMouseDown: TMouseEvent;
    FOnMouseMove: TMouseMoveEvent;
    FOnSpriteMouseMove: SE_SpriteMouseMoveEvent;
    FOnSpriteMouseDown: SE_SpriteMouseEvent;
    FOnSpriteMouseUp: SE_SpriteMouseEvent;
    FOnCellMouseUp: SE_GridMouseEvent;
    FOnCellMouseDown: SE_GridMouseEvent;
    FOnCellMouseMove: SE_GridMouseMoveEvent;

    FOnTheaterMouseMove: SE_TheaterMouseMoveEvent;
    FOnTheaterMouseDown: SE_TheaterMouseEvent;
    FOnTheaterMouseUp: SE_TheaterMouseEvent;

    // Thread
    FAnimationInterval: integer;
    FShowPerformance: boolean;
    nPerformanceEnd: DWORD;
    nFrames, nShowFrames: integer;

    // various
    lsTEngines: TObjectList<SE_Engine>;
    FBeforeSpriteRender: SE_TheaterEvent;
    FAfterSpriteRender: SE_TheaterEvent;
    FBeforeVisibleRender: SE_TheaterEvent;
    FAfterVisibleRender: SE_TheaterEvent;

    procedure SetCellsX (const v: integer);   // NON setta automaticamente la virtualwidth
    procedure SetCellsY (const v: integer);   // NON setta automaticamente la virtualHeight
    procedure SetGridStyle (const aGridStyle: TGridStyle);

    procedure SetCellWidth (const v: integer);
    procedure SetCellHeight (const v: integer);
    procedure SetHexSmallWidth (const v: integer);

    procedure SetVirtualWidth(const v: integer);
    procedure SetVirtualHeight(const v: integer);
    procedure SetViewX(v: integer);
    procedure SetViewY(v: integer);
    procedure SetZoom(v: double);

    procedure SetCollisionDelay  ( const nDelay: Integer);

    procedure SetBackColor(const aColor: Tcolor);
    procedure OnTimer (Sender: TObject);
    procedure SetAfterVisibleRender (const Value: SE_TheaterEvent);
    procedure SetBeforeVisibleRender (const Value: SE_TheaterEvent);
    procedure SetOnSpriteMouseMove(const Value: SE_SpriteMouseMoveEvent);
    procedure SetOnSpriteMouseDown(const Value: SE_SpriteMouseEvent);
    procedure SetOnSpriteMouseUp(const Value: SE_SpriteMouseEvent);

    function GetEngine(n: integer): SE_Engine;
    function GetEngineCount: integer;

    procedure SetActive(const Value: boolean);
    procedure FinalPaint(ABitmap: SE_Bitmap; ABitmapScanline: ppointerarray);
    procedure DrawHexCell( AOffSet : TPoint; AHexCellSize : THexCellSize; ACol, ARow : Integer );
    function GetHexDrawPoint( AHexCellSize : THexCellSize; ACol, ARow : Integer ) : TPoint;
    function GetHexCellPoints( AOffSet : TPoint; AHexCellSize : THexCellSize; ACol, ARow : Integer ): TpointArray7;




  protected
    fpassive: Boolean;
    fViewX, fViewY: integer;
    fZoom: double;
    fZoomDiv100: double;   // fZoom/100   settati come varibaili per non calcolarsi ogni volta
    f100DivZoom: double;   // 100/fZoom

    fOffsetX, fOffsetY: integer;  // Offset del VisibleBitmap sul VirtualBitmap
    fPaintWidth, fPaintHeight: integer;  // una immagine molto zoomata OUT pu� divenire molto piccola.
    ZoomWidth, ZoomHeight: integer;  // una immagine molto zoomata IN pu� divenire virtualmente enorme

    fLastMouseMoveX, fLastMouseMoveY: integer;  // coordinate reali del Bitmap
    fMouseDownX, fMouseDownY: integer;  // coordinate del mouse effettive come fosse una Form

    procedure DoMouseWheelScroll(Value, X, Y: integer);
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
    procedure WMEraseBkgnd(var Message: TMessage); message WM_ERASEBKGND;
    procedure WMMouseWheel(var Message: TMessage); message WM_MOUSEWHEEL;
    function GetVisibleBitmapRect : TRect;
    procedure GetPaintCoords(var XSrc, YSrc, SrcWidth, SrcHeight: integer; var DstWidth, DstHeight: integer; tViewX, tViewY: integer);
    procedure Update;


    function GetVisibleBitmap: SE_Bitmap;
    function GetVirtualBitmap: SE_Bitmap;

    // iratheater
    procedure AttachSpriteEngine( AEngine: SE_Engine );
    procedure DetachSpriteEngine( AEngine: SE_Engine );
    function GetMouseX( X: integer ): integer;
    function GetMouseY( Y: integer ): integer;

    procedure SortEngines;
    procedure DrawGrid;
    procedure PaintVisibleBitmap(Interval: integer);


  public
    lstSpritesHandled: Boolean;
    Angle: Integer;
    ChangeCursor : Boolean;
    SceneName: string;
    fUpdating: Boolean;
    lstSpriteClicked: TObjectList<SE_Sprite>;
    lstSpriteMoved: TObjectList<SE_Sprite>;

    thrdAnimate: SE_ThreadTimer;
    constructor Create(Owner: TComponent); override;
    destructor Destroy; override;
    procedure Loaded; override;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    function XVisibleToVirtual(x: integer): integer;
    function YVisibleToVirtual(y: integer): integer;
    function XVirtualToVisible(x: integer): integer;
    function YVirtualToVisible(y: integer): integer;

    procedure GetMaxViewXY(var mx, my: integer);
    procedure SaveInfoZoom(v: double);
    procedure ResetState();
    // Display

    procedure RefreshSurface(Sender: TObject);virtual;
    procedure CenterTheater;
    property ViewX: integer read fViewX write SetViewX;
    property ViewY: integer read fViewY write SetViewY;
    procedure SetViewXY(x, y: integer);
    property Zoom: double read fZoom write SetZoom;
    procedure ZoomAt(x, y: integer; ZoomVal: double);
    procedure ZoomIn;
    procedure ZoomOut;
    property OffsetX: integer read fOffsetX;
    property OffsetY: integer read fOffsetY;
    property PaintWidth: integer read fPaintWidth;
    property PaintHeight: integer read fPaintHeight;

    property MouseCapture;


    // Other
    procedure Assign(Source: TObject); reintroduce; virtual;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    procedure Clear;

    property VisibleBitmap : SE_Bitmap read getVisibleBitmap;
    property VirtualBitmap : SE_Bitmap read getVirtualBitmap;
    procedure Map(const WorldX: Single; const WorldY: Single; const adjust: boolean; out DisplayX: Integer; out DisplayY: Integer);
    procedure UnMap(const DisplayX: Integer; const DisplayY: Integer; out WorldX: Single;  out WorldY: Single);

    property EngineCount: integer read GetEngineCount;
    property Engines[n: integer]: SE_Engine read GetEngine;
    property Active: Boolean read FActive write SetActive;

  published

    property MouseScrollRate: Double read fMouseScrollRate write fMouseScrollRate;
    property MouseWheelInvert: boolean read fMouseWheelInvert write fMouseWheelInvert;
    property MouseWheelValue: integer read fMouseWheelValue write fMouseWheelValue;
    property MouseWheelZoom: boolean read FMouseWheelZoom write FMouseWheelZoom;
    property MousePan: boolean read FMousePan write FMousePan;
    property MouseScroll: boolean read FMouseScroll write FMouseScroll;

    property BackColor : Tcolor read fBackColor write setBackColor;

    property AnimationInterval: integer read FAnimationInterval write FAnimationInterval;

    property GridInfoCell: boolean read FGridInfoCell write FGridInfoCell;
    property GridVisible: boolean read FGridVisible write FGridVisible;
    property Grid: TGridStyle read FGrid write SetGridStyle default gsnone;
    property GridColor: TColor read FGridColor write FGridColor default clBlack;
    property GridCellWidth: integer read FCellWidth write SetCellWidth default 100;
    property GridCellHeight: integer read FCellHeight write SetCellHeight default 100;
    property GridCellsX: integer read FCellsX write SetCellsx stored true;
    property GridCellsY: integer read FCellsY write SetCellsy stored true;
    property GridHexSmallWidth: integer read FHexSmallWidth write SetHexSmallWidth;


    property CollisionDelay: integer read fCollisionDelay write SetCollisionDelay default 400;



    property ShowPerformance: boolean read FShowPerformance write FShowPerformance;
    property OnCellMouseDown: SE_GridMouseEvent read FOnCellMouseDown write FOnCellMouseDown;
    property OnCellMouseMove: SE_GridMouseMoveEvent read FOnCellMouseMove write FOnCellMouseMove;
    property OnCellMouseUp: SE_GridMouseEvent read FOnCellMouseUp write FOnCellMouseUp;

    property OnBeforeVisibleRender: SE_TheaterEvent read FBeforeVisibleRender write SetBeforeVisibleRender;
    property OnAfterVisibleRender: SE_TheaterEvent read FAfterVisibleRender write SetAfterVisibleRender;

    property OnSpriteMouseMove: SE_SpriteMouseMoveEvent read FOnSpriteMouseMove write SetOnSpriteMouseMove;
    property OnSpriteMouseDown: SE_SpriteMouseEvent read FOnSpriteMouseDown write SetOnSpriteMouseDown;
    property OnSpriteMouseUp: SE_SpriteMouseEvent read FOnSpriteMouseUp write SetOnSpriteMouseUp;

    property OnTheaterMouseMove: SE_TheaterMouseMoveEvent read FOnTheaterMouseMove write FOnTheaterMouseMove;
    property OnTheaterMouseDown: SE_TheaterMouseEvent read FOnTheaterMouseDown write FOnTheaterMouseDown;
    property OnTheaterMouseUp: SE_TheaterMouseEvent read FOnTheaterMouseUp write FOnTheaterMouseUp;

    property VirtualWidth: integer read fVirtualWidth write SetVirtualWidth;
    property Virtualheight: integer read fVirtualheight write SetVirtualheight;
    property Passive : boolean read fPassive write fpassive default False;

    property Anchors;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;

    property DragCursor;

    property Cursor;

    property Align;
    property DragMode;
    property Enabled;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;
    property TabOrder;
    property TabStop;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDrag;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnContextPopup;



  end;
  pSE_SpriteLabel = ^SE_SpriteLabel;

  SE_SpriteMoverData = class( TObject )
  private
    FDestinationY: integer;
    FDestinationX: integer;

    FDestinationReach: TPoint;
    FDestinationYReach: integer;
    FDestinationXreach: integer;
    FreachPerc: Integer;

    fWPinterval: Integer;

    FDestinationCellY: integer;
    FDestinationCellX: integer;

    FSpeed: single;
    FSpeedY: single;
    FSpeedX: single;
    function GetDestination(  ): TPoint;
    procedure SetDestination(  Destination: TPoint );
    procedure SetReachPerc(  perc: integer );
    procedure setWPinterval ( v: Integer );
    function GetDestinationCell(  ): TPoint;
    procedure SetDestinationCell(  DestinationCell: TPoint );
    procedure CalculateVectors( );
  protected
  public
    FSprite: SE_Sprite;

    curWP: Integer;
    TWPinterval: Integer;   // ms tra un movepathpoint e l'altro
    MovePath: TList<TPoint>;
    UseMovePath: boolean;

    constructor Create ; overload;
    destructor Destroy; override;

    property WPinterval: Integer read fWPinterval write setWPinterval;   // ms tra un movepathpoint e l'altro

    property Destination: Tpoint read GetDestination write SetDestination;

    property Destinationreach: Tpoint read FDestinationReach write FDestinationReach;
    property ReachPerc: Integer read freachPerc write SetReachPerc;



    property DestinationCell: Tpoint read GetDestinationCell write SetDestinationCell;

    property Speed: single read FSpeed write FSpeed;
    property SpeedX: single read FSpeedX write FSpeedX;
    property SpeedY: single read FSpeedY write FSpeedY;


  end;


  SE_Engine = class( TComponent )
  private
    lstSprites: TObjectList<SE_Sprite>;
    lstNewSprites: TObjectList<SE_Sprite>;



    FOnCollision: TCollisionEvent;
    FOnSpriteDestinationReached: SE_EngineEvent;
    FOnSpriteDestinationReachedPerc: SE_EngineEvent;

    FPixelClick: Boolean;
    FPixelCollision: Boolean;
    FIsoPriority: Boolean;
    FPriority: integer;
    FClickSprites: boolean;
    FSortNeeded: boolean;
    FrenderBitmap: TRenderBitmap;

    lstEngines: TObjectList<SE_Engine>;
    FVisible: boolean;
    procedure SetTheater(const Value: SE_Theater);
    function GetSprite(n: integer): SE_Sprite;
    function GetSpriteIndex(aSprite: SE_Sprite): Integer;
    function GetSpriteCount: integer;
    procedure SetPriority(const Value: integer);
    procedure SetOnCollision(const Value: TCollisionEvent);
    procedure SetOnSpriteDestinationReached(const Value: SE_EngineEvent);

    procedure SetVisible(const Value: boolean);
  protected
    function GetDestination( ASprite: SE_Sprite ): TPoint;
    procedure SetDestination(ASprite: SE_Sprite;  Destination: TPoint);

    procedure CollisionDetection;

    procedure Notification( AComponent: TComponent; Operation: TOperation ); override;
    procedure RenderSprites;
    procedure SortSprites;
  public

    FTheater: SE_Theater;
    constructor Create( AOwner: TComponent ); override;
    destructor Destroy; override;

    function IsAnySpriteMoving : Boolean;
    procedure ProcessSprites(interval: Integer);
    function CreateSprite( const FileName,Guid: string; nFramesX, nFramesY, nDelay, posX, posY: integer; const Transparent: boolean ): SE_Sprite;overload;
    function CreateSprite(const bmp: TBitmap; const Guid: string; nFramesX, nFramesY, nDelay, posX, posY: integer; const Transparent: boolean  ): SE_Sprite; overload;
    procedure AddSprite(aSprite: SE_Sprite) ;

    procedure Clear;
    procedure RemoveAllSprites;
    procedure RemoveSprite( ASprite: SE_Sprite );
    property SpriteCount: integer read GetSpriteCount;
    property Sprites[n: integer]: SE_Sprite read GetSprite;
    property SpriteIndex[aSprite: SE_Sprite]: integer read GetSpriteIndex;
    Function FindSprite (Guid: string):SE_sprite;

    property Destination[Sprite: SE_Sprite]: TPoint read GetDestination write SetDestination;
  published
    property ClickSprites: boolean read FClickSprites write FClickSprites default true;
    property PixelClick: boolean read FPixelClick write FPixelClick default false;
    property PixelCollision: boolean read FPixelCollision write FPixelCollision;
    property IsoPriority: boolean read FIsoPriority write FIsoPriority;
    property Priority: integer read FPriority write SetPriority;
    property Theater: SE_Theater read FTheater write SetTheater;
    property Visible: boolean read FVisible write SetVisible default true;
    property RenderBitmap: TrenderBitmap read FrenderBitmap write FrenderBitmap default VirtualRender;
    property OnCollision: TCollisionEvent read FOnCollision write SetOnCollision;
    property OnSpriteDestinationReached: SE_EngineEvent read FOnSpriteDestinationReached write FOnSpriteDestinationReached;
    property OnSpriteDestinationReachedPerc: SE_EngineEvent read FOnSpriteDestinationReachedPerc write FOnSpriteDestinationReachedPerc;
//    property OnSpriteMoving: SE_EngineEvent read FOnSpriteMoving write FOnSpriteMoving;
  end;


  SE_Sprite = class( TObject )
  private

    FBMP, FBMPalpha: SE_Bitmap;
    FBMPCurrentFrame,FBMPCurrentFrameAlpha: SE_Bitmap;
    fchangingFrame: boolean;
    fchangingBitmap: boolean;


    FAnimated: boolean;
    FFrameWidth, FFrameHeight: integer;
    FFrameX: integer;
    FFrameY: integer;
    FFramesX: integer;
    FFramesY: integer;
    FAnimationDirection: SE_Direction;
    FFrameXmin: integer;
    FFrameXmax: integer;

    FAnimationInterval: integer;
    FHideAtEndX: Boolean;
    FDieAtEndX: Boolean;
    FStopAtEndX: Boolean;

    FTransparent: boolean;
    FTransparentColor: TColor;
    FTransparentForced: Boolean;
    lstLabels: Tobjectlist<SE_SpriteLabel>;
    lstSubSprites: Tobjectlist<SE_SubSprite>;

    FVisible: boolean;
    FPriority: integer;
    FModPriority:integer;

    FFlipped: boolean;
    FAngle: single;
    FAutoRotate: boolean;
    FPositionY: single;
    FPositionX: single;
    FPosition: Tpoint;
    FPositionCell: Tpoint;                   // if theater.GridMode <> gsNone


    FDrawingRect: Trect;

    FNotifyDestinationReached : boolean;
    FNotifyDestinationReachedPerc: boolean;


    FDead: boolean;
    FLifeSpan: integer; // utile per distanza in pixel
    fDelay: integer;

    fsOffsetX: integer;
    fsOffsetY: integer;


    fAlpha: double;
    fScale: integer;
    fBlendMode: SE_BlendMode;

    Fpause: boolean;
    fGrayScaled: boolean;

    FTheater: SE_Theater;
    FEngine: SE_Engine;
    FMoverData: SE_SpriteMoverData;

    FOnDestinationReached: SE_SpriteEventDstReached;
    FOnDestinationReachedPerc: SE_SpriteEventDstReached;

    function getTransparentColor: TRGB;
    procedure SetPositionX(const Value: single);
    procedure SetPositionY(const Value: single);

    procedure SetScale(const Value: integer);
    procedure SetBlendMode(const Value: SE_BlendMode);
    procedure SetAlpha(const Value: double);

    procedure SetTransparent(const Value: Boolean);
    procedure SetPriority(const Value: integer);

    function GetPositionX: single;
    function GetPositionY: single;
    function GetPosition: TPoint;
    procedure SetPosition(const Value: TPoint);
    procedure SetAngle(const Value: single);
    procedure SetFrameXmin (const Value: Integer);
    procedure SetFrameXmax (const Value: Integer);

    procedure SetDead(const Value: boolean);

  protected

  public
    Guid: string;
    SpriteFileName : string;
    useBmpDimension: Boolean;
    DestinationReached : boolean;
    DestinationReachedPerc : boolean;
    sTag : string;
    CollisionIgnore: Boolean;
    MouseX, MouseY : integer; // coordinate del mouse attuali su questo SE_Sprite
    constructor Create();overload ; virtual;
    constructor Create ( const FileName,Guid: string; const nFramesX, nFramesY, nDelay, posX, posY: integer; const TransparentSprite: boolean);overload; virtual;
    constructor Create ( const  bmp: Tbitmap; const Guid: string; const nFramesX, nFramesY, nDelay, posX, posY: integer; const TransparentSprite: boolean);overload; virtual;
    procedure ChangeBitmap ( const FileName: string; const nFramesX, nFramesY, nDelay: integer);overload; virtual;
    procedure ChangeBitmap ( const  bmp: Tbitmap;  const nFramesX, nFramesY, nDelay: integer);overload; virtual;

    destructor Destroy; override;
    procedure iOnDestinationReached ; virtual;
    procedure iOnDestinationReachedPerc ; virtual;


//    procedure MouseUp ( x,y: integer; Button: TMouseButton; Shift: TShiftState; var handled: boolean); virtual;
//    procedure MouseDown ( x,y: integer; Button: TMouseButton; Shift: TShiftState; var handled: boolean); virtual;
//    procedure MouseMove ( x,y: integer; Shift: TShiftState; var handled: boolean); virtual;

    procedure Move(interval: Integer); virtual;
    procedure SetCurrentFrame; virtual;
    procedure DrawFrame; virtual;
    procedure Render(RenderTo: TRenderBitmap);  virtual;

    procedure SetPositionCell(const Value: TPoint);
    procedure MakeDelay(msecs: integer);

    function FindSubSprite ( Guid : string): SE_SubSprite;
    procedure AddSubSprite ( aSubSprite : SE_SubSprite);
    procedure DeleteSubSprite ( Guid : string);
    procedure RemoveAllSubSprites;
    function  CollisionDetect ( aSprite: SE_sprite ): Boolean;

    property Dead: boolean read FDead write SetDead;
    property LifeSpan: integer read FLifeSpan write FLifeSpan;


    property Position: TPoint read GetPosition write SetPosition;
    property PositionCell: TPoint read fPositionCell write SetPositionCell;
    property PositionX: single read GetPositionX write SetPositionX;
    property PositionY: single read GetPositionY write SetPositionY;

    property Flipped: boolean read FFlipped write FFlipped;
    property Angle: single read fAngle write SetAngle;
    property AutoRotate: boolean read fAutoRotate write fAutoRotate;


    property ModPriority: integer read FModPriority write FModPriority;
    property Priority: integer read FPriority write SetPriority;
    property Engine: SE_Engine read FEngine;
    property MoverData: SE_SpriteMoverData read FMoverData write FMoverData;
    property Theater: SE_Theater read FTheater write Ftheater;

    property DrawingRect: Trect read FDrawingRect write FDrawingRect;


    property BMP: SE_Bitmap read FBMP write FBMP;
    property BMPAlpha: SE_Bitmap read FBMPAlpha write FBMPAlpha;
    property Alpha: double read Falpha write SetAlpha;
    property Visible : boolean read FVisible write FVisible default true;


    property NotifyDestinationReached : boolean read FNotifyDestinationReached write FNotifyDestinationReached;
    property NotifyDestinationReachedPerc : boolean read FNotifyDestinationReachedPerc write FNotifyDestinationReachedPerc;

    property FrameWidth: integer read FFrameWidth write FFrameWidth;
    property FrameHeight: integer read FFrameHeight write FFrameHeight;

    property AnimationDirection: SE_Direction read FAnimationDirection write FAnimationDirection;
    property AnimationInterval: integer read FAnimationInterval write FAnimationInterval;
    property HideAtEndX: Boolean read FHideAtEndX write FHideAtEndX default false ;
    property DieAtEndX: Boolean read FDieAtEndX write FDieAtEndX default false;
    property StopAtEndX: Boolean read FStopAtEndX write FStopAtEndX default false ;

    property FrameX: integer read FFrameX write FFrameX;
    property FrameY: integer read FFrameY write FFrameY;
    property FramesX: integer read FFramesX write FFramesX;
    property FramesY: integer read FFramesY write FFramesY;
    property FrameXmin: integer read FFrameXmin write SetFrameXmin;
    property FrameXmax: integer read FFrameXmax write SetFrameXmAx;
    property BmpCurrentFrame: se_bitmap read FbmpcurrentFrame write FbmpcurrentFrame;

    property delay: integer read Fdelay write Fdelay;
    property soffsetX: integer read FsoffsetX write FsoffsetX;
    property soffsetY: integer read FsoffsetY write FsoffsetY;
    property Scale: integer read fScale write SetScale;
    property BlendMode: SE_BlendMode read fBlendMode write SetBlendMode;
    property GrayScaled: boolean read fGrayScaled write fGrayScaled;


    property Transparent: boolean read FTransparent write setTransparent;
    property TransparentColor: Tcolor read FTransparentColor write FTransparentColor;
    property TransparentForced: boolean read FTransparentForced write FTransparentForced;
    property Pause: boolean read FPause write FPause ;

    property Labels : Tobjectlist<SE_SpriteLabel> read lstLabels write lstLabels;
    property SubSprites: Tobjectlist<SE_SubSprite> read lstSubSprites write lstSubSprites;

    property OnDestinationreached : SE_SpriteEventDstReached read FOnDestinationreached write FOnDestinationreached;
    property OnDestinationreachedPer : SE_SpriteEventDstReached read FOnDestinationreachedPerc write FOnDestinationreachedPerc;


  end;

  procedure GetLinePoints(X1, Y1, X2, Y2 : Integer; var PathPoints: dse_pathplanner.TPath); overload;
  procedure GetLinePoints(X1, Y1, X2, Y2 : Integer; var PathPoints: TList<TPoint>); overload;
  function AngleOfLine(const P1, P2: TPoint): Double;
procedure Register;
implementation


uses math,  Types;
procedure Register;
begin
  RegisterComponents('DSE', [
  SE_ThreadTimer,
  SE_Theater,
  SE_Engine
  //TAStardse_pathplanner,
  //TSimpledse_pathplanner,
  //TSearchableMap,
 //TStateFactory


{  ,
  TSoccerSpriteServer,
  TCharacterSpriteServer,
  TSpellSpriteServer,
  TGrGuidpriteServer,
  TButtonBarSpriteServer

  }
  ]);

end;


{$R-}
// ----------------------------------------------------------------------------
// GetLinePoints
// ----------------------------------------------------------------------------
function ReversePointOrder(LinePointList : TList<TPoint>) : TList<TPoint>;
var
  NewPointList : TList<TPoint>;
begin
  NewPointList := TList<TPoint>.Create;
  NewPointList:=LinePointList;
  NewPointList.Reverse ;
  Result := NewPointList;
end;
procedure GetLinePoints(X1, Y1, X2, Y2 : Integer; var PathPoints: TList<TPoint>);
var
ChangeInX, ChangeInY, i, MinX, MinY, MaxX, MaxY, LineLength : Integer;
ChangingX : Boolean;
Point : TPoint;
begin
  PathPoints.Clear;

  if X1 > X2 then  begin
    ChangeInX := X1 - X2;
    MaxX := X1;
    MinX := X2;
  end
  else begin
    ChangeInX := X2 - X1;
    MaxX := X2;
    MinX := X1;
  end;

  if Y1 > Y2 then  begin
    ChangeInY := Y1 - Y2;
    MaxY := Y1;
    MinY := Y2;
  end
  else  begin
    ChangeInY := Y2 - Y1;
    MaxY := Y2;
    MinY := Y1;
  end;

  if ChangeInX > ChangeInY then  begin
    LineLength := ChangeInX;
    ChangingX := True;
  end
  else begin
    LineLength := ChangeInY;
    ChangingX := false;
  end;


  if X1 = X2 then  begin
    for i := MinY to MaxY do begin
      Point.X := X1;
      Point.Y := i;
      PathPoints.Add(Point);
    end;

    if Y1 > Y2 then  begin
      PathPoints.reverse;
    end;
  end

  else if Y1 = Y2 then  begin
    for i := MinX to MaxX do begin
      Point.X := i;
      Point.Y := Y1;
      PathPoints.Add(Point);
    end;


    if X1 > X2 then begin
      PathPoints.reverse;
    end;
  end
  else begin
    Point.X := X1;
    Point.Y := Y1;
    PathPoints.Add(Point);

    for i := 1 to (LineLength - 1) do  begin
      if ChangingX then  begin
        Point.y := Round((ChangeInY * i)/ChangeInX);
        Point.x := i;
      end

      else  begin
        Point.y := i;
        Point.x := Round((ChangeInX * i)/ChangeInY);
      end;

      if Y1 < Y2 then  Point.y := Point.Y + Y1
      else   Point.Y := Y1 - Point.Y;

      if X1 < X2 then  Point.X := Point.X + X1
      else   Point.X := X1 - Point.X;

      PathPoints.Add(Point);
    end;
    Point.X := X2;
    Point.Y := Y2;
    PathPoints.Add(Point);
  end;
end;

procedure GetLinePoints(X1, Y1, X2, Y2 : Integer; var PathPoints: dse_pathplanner.TPath);
var
ChangeInX, ChangeInY, i, MinX, MinY, MaxX, MaxY, LineLength : Integer;
ChangingX : Boolean;
Point : TPoint;
//ReturnList, ReversedList : dse_pathplanner.TPath;
begin
  PathPoints.Clear;
//  ReturnList := dse_pathplanner.TPath.Create;
 // ReversedList := dse_pathplanner.TPath.Create;


  if X1 > X2 then  begin
    ChangeInX := X1 - X2;
    MaxX := X1;
    MinX := X2;
  end
  else begin
    ChangeInX := X2 - X1;
    MaxX := X2;
    MinX := X1;
  end;

  // Get the change in the Y axis and the Max & Min Y values
  if Y1 > Y2 then  begin
    ChangeInY := Y1 - Y2;
    MaxY := Y1;
    MinY := Y2;
  end
  else  begin
    ChangeInY := Y2 - Y1;
    MaxY := Y2;
    MinY := Y1;
  end;

  // Find out which axis has the greatest change
  if ChangeInX > ChangeInY then  begin
    LineLength := ChangeInX;
    ChangingX := True;
  end
  else begin
    LineLength := ChangeInY;
    ChangingX := false;
  end;


  if X1 = X2 then  begin
    for i := MinY to MaxY do begin
      Point.X := X1;
      Point.Y := i;
      PathPoints.Add(Point.X,Point.y);
    end;

    if Y1 > Y2 then  begin
  //  ReversedList := ReversePointOrder(ReturnList);  { ReturnList.reverse e basta }
  // ReturnList := ReversedList;
      PathPoints.reverse;
    end;
  end

  else if Y1 = Y2 then  begin
    for i := MinX to MaxX do begin
      Point.X := i;
      Point.Y := Y1;
      PathPoints.Add(Point.x,Point.Y );
    end;


    if X1 > X2 then begin
//      ReversedList := ReversePointOrder(ReturnList);
//      ReturnList := ReversedList;
      PathPoints.reverse;
    end;
  end
  else begin
    Point.X := X1;
    Point.Y := Y1;
    PathPoints.Add(Point.x,Point.y);

    for i := 1 to (LineLength - 1) do  begin
      if ChangingX then  begin
        Point.y := Round((ChangeInY * i)/ChangeInX);
        Point.x := i;
      end

      else  begin
        Point.y := i;
        Point.x := Round((ChangeInX * i)/ChangeInY);
      end;

      if Y1 < Y2 then  Point.y := Point.Y + Y1
      else   Point.Y := Y1 - Point.Y;

      if X1 < X2 then  Point.X := Point.X + X1
      else   Point.X := X1 - Point.X;

      PathPoints.Add(Point.X,Point.y);
    end;
  // Add the second point to the list.
    Point.X := X2;
    Point.Y := Y2;
    PathPoints.Add(Point.X,Point.y);
  end;
//Result := ReturnList;
end;

function AngleOfLine(const P1, P2: TPoint): Double;
begin
  Result := RadToDeg(ArcTan2((P2.Y - P1.Y),(P2.X - P1.X)));
  if result >180 then result:=result-360;
  if result<= -180 then result:=result+360;
end;
constructor SE_SpriteLabel.create ( x,y: integer; FontName: string; FontColor, BackColor: TColor; atext: string;aPenMode: TPenMode; visible: boolean);
begin
  lx := x;
  ly := y;
  lFont:= TFont.Create ;
  lFont.Name := FontName;
  lFont.Color := FontColor;
  ltext:= atext;
  lPenMode:= aPenMode;
  lVisible:= visible;
  lbackcolor := BackColor;
end;
destructor SE_SpriteLabel.Destroy;
begin
  inherited;
end;
constructor SE_SubSprite.create (bmpFilename,Guid:string; x,y: integer; visible,Transparent: boolean);
begin
    lTransparent:= Transparent;
    lX := x;
    lY := y;
    lVisible:= Visible ;
    //lBackColor:= BackColor;
    lBmp:= SE_Bitmap.Create ( bmpFilename );
    self.guid := Guid;
    stag:= Guid;
    LifeSpan := 0;
end;
constructor SE_SubSprite.create (bmp:SE_Bitmap;Guid:string; x,y: integer; visible,transparent: boolean);
begin
    lTransparent:= Transparent;
    lX := x;
    lY := y;
    lVisible:= Visible ;
   // lBackColor:= BackColor;
    lBmp:= SE_Bitmap.Create ( bmp );
    self.guid := Guid;
    stag:= Guid;
    LifeSpan := 0;
end;
destructor SE_SubSprite.Destroy;
begin
    lbmp.Free;
    inherited;
end;

function SE_SpriteMoverData.GetDestination(): TPoint;
begin
    Result := Point( fDestinationX, fDestinationY );
end;
function SE_SpriteMoverData.GetDestinationCell(): TPoint;
begin
    Result := Point( fDestinationCellX, fDestinationCellY );
end;
procedure SE_SpriteMoverData.SetDestination(Destination: TPoint);
begin
  FreachPerc := 0;
  fDestinationX := Destination.X;
  fDestinationY := Destination.Y;
  CalculateVectors;
end;
procedure SE_SpriteMoverData.setWPinterval ( v: Integer );
begin
  fWPinterval := v;
  tWPinterval := v;
end;
procedure SE_SpriteMoverData.SetReachPerc(  perc: integer );
var
  aPath: dse_pathplanner.TPath;
  x: Integer;
begin
  FreachPerc:= perc;
  aPath:= dse_pathplanner.TPath.Create;
  GetLinePoints( FSprite.Position.X,  FSprite.Position.Y, fDestinationX, fDestinationY, aPath) ;

  x:= (aPath.count * FreachPerc)  div 100;
  fDestinationXReach := aPath[x].X;
  fDestinationYReach :=  aPath[x].Y;
  aPath.Free;
  CalculateVectors;

end;

procedure SE_SpriteMoverData.SetDestinationCell(DestinationCell: TPoint);
var
X,Y: Integer;
begin

  FSprite.Theater.Map(Trunc(DestinationCell.X), Trunc(DestinationCell.Y) , false, X ,Y  );
  FDestinationX:= X ;
  FDestinationY:= Y ;

  CalculateVectors;
end;
procedure SE_Theater.AttachSpriteEngine(AEngine: SE_Engine);
begin
  if not (csDesigning in ComponentState) then  begin
    lsTEngines.Add( AEngine );
    SorTEngines;
  end;
end;
constructor SE_SpriteMoverData.create ;
begin
  MovePath:= TList<TPoint>.Create ;
  curWP := 0;
end;
destructor SE_SpriteMoverData.Destroy ;
begin
  MovePath.Free;
end;

procedure SE_SpriteMoverData.CalculateVectors;
var
  Dist: single;
  xpct, ypct: single;
begin


  Dist := Abs( fDestinationX - fSprite.PositionX ) + Abs( fDestinationY - fSprite.PositionY );
  if ( Dist > 0 ) then
  begin
    xPct := Abs( fDestinationX - fSprite.PositionX ) / Dist;
    yPct := Abs( fDestinationY - fSprite.PositionY ) / Dist;
    SpeedX := Speed * xPct;
    SpeedY := Speed * yPct;
    if ( fDestinationX < fSprite.PositionX ) then
      SpeedX := -SpeedX;
    if ( fDestinationY < fSprite.PositionY ) then
      SpeedY := -SpeedY;
  end
  else
  begin
    SpeedX := Speed / 2.0;
    SpeedY := Speed / 2.0;
  end;
end;
function SE_Engine.GetDestination(ASprite: SE_Sprite): TPoint;
begin
    Result := ASprite.MoverData.Destination;
end;



procedure SE_Theater.DetachSpriteEngine(AEngine: SE_Engine);
var
  n: integer;
begin
  if not (csDesigning in ComponentState) then
  begin
  n := lstEngines.IndexOf( AEngine );
  if n >= 0 then
    lstEngines.Delete( n );
  end;
end;

function SE_Theater.GetMouseX(X: integer): integer;
begin
  Result := X + viewX + OffsetX;
end;

function SE_Theater.GetMouseY(Y: integer): integer;
begin
  Result := Y + viewY + OffsetY;
end;


function SE_Theater.GetEngine(n: integer): SE_Engine;
begin
  Result :=  lstEngines.items[n];
end;

function SE_Theater.GetEngineCount: integer;
begin
  Result := lstEngines.Count;
end;
procedure SE_Theater.RefreshSurface(Sender: TObject);
var
  i: integer;
begin

  Inc( nFrames );

  fVirtualBitmap.Canvas.Brush.Color := fBackColor;
  fVirtualBitmap.Canvas.FillRect( Rect(0,0,fVirtualBitmap.Width,fVirtualBitmap.Height));

  if Assigned( FBeforeSpriteRender ) then  FBeforeSpriteRender( self,  fVirtualBitmap, fVisibleBitmap );



  if not fUpdating then begin
//   SortEngines;
   lstEngines.sort(TComparer<SE_Engine>.Construct(
   function (const L, R: SE_Engine): integer
   begin
      result := trunc(R.Priority  - L.Priority  );
   end
  ));


    for i := lstEngines.Count - 1 downto 0 do  begin
      if lstEngines.items[i].RenderBitmap = VirtualRender then begin
//        lstEngines.items[i].ProcessSprites(GetTickCount - SE_ThreadTimer(Sender).Interval  );
        lstEngines.items[i].ProcessSprites( SE_ThreadTimer(Sender).Interval  );
        lstEngines.items[i].RenderSprites;
        iCollisionDelay := iCollisionDelay -  SE_ThreadTimer(Sender).Interval ;
        if iCollisionDelay <= 0 then begin
          iCollisionDelay := fCollisionDelay;
          lstEngines.items[i].CollisionDetection ;
        end;

      end;
    end;

    if Assigned( FAfterSpriteRender ) then
      FAfterSpriteRender( self, fVirtualBitmap, fVisibleBitmap );


  DrawGrid;  // scrive su fVirtualBitmap, non sul canvas finale

  PaintVisibleBitmap (SE_ThreadTimer(Sender).Interval);

 end;

  Application.ProcessMessages;

end;
procedure SE_Theater.OnTimer(Sender: TObject);
begin
  if FActive then
    RefreshSurface(SE_ThreadTimer(Sender));
end;

procedure SE_Theater.SetActive(const Value: boolean);
begin

  if not (csDesigning in ComponentState) then begin
    FActive := Value;
    if Not FActive and not fPassive then begin
      thrdAnimate.Enabled := False;
    end
    else begin
      if not fpassive then thrdAnimate.Enabled := True ;
    end;
  end;
end;


procedure SE_Theater.SetAfterVisibleRender (const Value: SE_TheaterEvent);
begin
  fAfterVisibleRender := value;
end;
procedure SE_Theater.SetBeforeVisibleRender (const Value: SE_TheaterEvent);
begin
  fBeforeVisibleRender := value;
end;
procedure SE_Theater.SetOnSpriteMouseMove(const Value: SE_SpriteMouseMoveEvent);
begin
  FOnSpriteMouseMove := Value;
end;

procedure SE_Theater.SetOnSpriteMouseDown(const Value: SE_SpriteMouseEvent);
begin
  FOnSpriteMouseDown := Value;
end;
procedure SE_Theater.SetOnSpriteMouseUp(const Value: SE_SpriteMouseEvent);
begin
  FOnSpriteMouseUp := Value;
end;


procedure SE_Theater.SortEngines;
begin
  lstEngines.sort(TComparer<SE_Engine>.Construct(
   function (const L, R: SE_Engine): integer
   begin
     result := trunc(L.Priority  - R.Priority  );
   end
  ));
end;

procedure SE_Theater.DrawGrid;
var
  x,y: Integer;

begin
    if not fGridVisible then exit;


    fVirtualBitmap.Canvas.Pen.Style:= psSolid;
    fVirtualBitmap.Canvas.pen.Color:= FGridColor;

  for y:= 0 to FCellsY - 1 do
    for x := 0 to FCellsX - 1 do
      DrawHexCell( Point(0,0), AHexCellSize, x, y );
end;

procedure SE_Theater.Map(const WorldX: Single; const WorldY: Single; const adjust: boolean; out DisplayX: Integer; out DisplayY: Integer);
begin
//q col= x row r =z
//function hex_to_pixel(hex):                    //pointy top
//    x = size * sqrt(3) * (hex.q + hex.r/2)
//    y = size * 3/2 * hex.r
//    Displayx := Round(FScale * sqrt(3) * (WorldX + WorldY / 2));
//    Displayy := Round(FScale * 3/2 * WorldY);
//function hex_to_pixel(hex):
//    x = size * 3/2 * hex.q                     // flat top
//    y = size * sqrt(3) * (hex.r + hex.q/2)

//function offset_to_pixel(hex):                             // odd-r
//    x = size * sqrt(3) * (hex.col + 0.5 * (hex.row&1))
//    y = size * 3/2 * hex.row
//    return Point(x, y)
//    function offset_to_pixel(hex):                       // even-r
//    x = size * sqrt(3) * (hex.col - 0.5 * (hex.row&1))
//    y = size * 3/2 * hex.row
//    return Point(x, y)
//function offset_to_pixel(hex):                           // odd-q
//    x = size * 3/2 * hex.col
//    y = size * sqrt(3) * (hex.row + 0.5 * (hex.col&1))
//    return Point(x, y)
//
//function offset_to_pixel(hex):                          // even-q
//    x = size * 3/2 * hex.col
//    y = size * sqrt(3) * (hex.row - 0.5 * (hex.col&1))
//    return Point(x, y)
//function pixel_to_hex(x, y):                 // pointy
//    q = (x * sqrt(3)/3 - y / 3) / size
//    r = y * 2/3 / size
//    return hex_round(Hex(q, r))
//    function pixel_to_hex(x, y):           // flat top
//    q = x * 2/3 / size
//    r = (-x / 3 + sqrt(3)/3 * y) / size
//    return hex_round(Hex(q, r))

//r = (sqrt(3)/3 * x - y/3 ) / s



  if FGrid = gsHex then begin
                                                                                  // sugli hex devo correggere per portarlo al centro
    if Adjust then begin
      DisplayX:= GethexDrawPoint ( aHexCellSize, round(WorldX), round(WorldY)).x    +  (aHexCellSize.SmallWidth div 2);
      DisplayY:= GethexDrawPoint ( aHexCellSize, round(WorldX), round(WorldY)).y    +  (aHexCellSize.Height  div 2);
    end
    else begin
      DisplayX:= GethexDrawPoint ( aHexCellSize, round(WorldX), round(WorldY)).x ;
      DisplayY:= GethexDrawPoint ( aHexCellSize, round(WorldX), round(WorldY)).y ;
    end;
  end;
end;
procedure SE_Theater.UnMap(const DisplayX: Integer; const DisplayY: Integer; out WorldX: Single;  out WorldY: Single);
var
  PtPoly: TpointArray7;
  x,y: integer;
  PolyHandle: HRGN;
  inside: boolean;

begin

  if FGrid  = gsHex then begin


//    worldy := Displayx * 2/3 / aHexCellSize.Height *2;
//    WorldX := (-Displayx / 3 + sqrt(3)/3 * displayy) / aHexCellSize.Height *2;
//
//    worldy := (Displayx * sqrt(3)/3 - displayy / 3) / aHexCellSize.Height *2 ;
//    WorldX := Displayy *2/3/ aHexCellSize.Height *2;
//
//function pixel_to_hex(x, y):

   // worldX := DisplayX * 2/3 / aHexCellSize.Height *2 ;
  //  worldy := DisplayY * 2/3/ aHexCellSize.Height *2;
    //return hex_round(Hex(q, r))  end;  r = y * 2/3 / size

  // se � nel poligono
    inside:= false;
    for x := 0 to FcellsX-1 do begin
      for y := 0 to FcellsY-1 do begin

        PtPoly := GetHexCellPoints( Point(0,0), AHexCellSize , x, y  );

        PolyHandle := CreatePolygonRgn(PtPoly[0],length(Ptpoly),Winding);
        inside     := PtInRegion(PolyHandle,DisplayX,DisplayY);
        DeleteObject(PolyHandle);
        if inside then begin
          worldX:=X;
          worldY:=Y;
          exit;
        end;

      end;
    end;

    if not Inside then begin
      WorldX := -1;
      WorldY := -1;

    end;
  end
  else begin
      WorldX := -1;
      WorldY := -1;
  end;
end;
procedure SE_Theater.DrawHexCell( AOffSet : TPoint; AHexCellSize : THexCellSize; ACol, ARow : Integer );
var
  LPoint : TPoint;
  LXOffset : Integer;
begin
  { *************
    *   1---2
    *  /     \
    * 6       3
    *  \     /
    *   5---4
    ************* }

  LXOffset := ( AHexCellSize.Width - AHexCellSize.SmallWidth ) div 2;

  // Move to point 1
  LPoint := GetHexDrawPoint( AHexCellSize, ACol, ARow );
  LPoint.Offset( AOffSet );
  fVirtualBitmap.Canvas.MoveTo( LPoint.X, LPoint.Y );

  // tra line 1 e line 2 Infocell
  if FGridInfoCell then begin
    fVirtualBitmap.Canvas.Font.Color := FGridColor;
    fVirtualBitmap.Canvas.Pen.Color :=FGridColor;
    fVirtualBitmap.Canvas.Brush.Style := bsClear;
    fVirtualBitmap.Canvas.TextOut(LPoint.X, LPoint.Y,IntToStr(Acol)+':'+ IntToStr(ARow));
  end;
    fVirtualBitmap.Canvas.Brush.Style := bsSolid;

  // Line to point 2
  LPoint.Offset( AHexCellSize.SmallWidth, 0 );
  fVirtualBitmap.Canvas.LineTo( LPoint.X, LPoint.Y );

  // Line to point 3
  LPoint.Offset( LXOffset, AHexCellSize.Height div 2 );
  fVirtualBitmap.Canvas.LineTo( LPoint.X, LPoint.Y );
  // Line to point 4
  LPoint.Offset( -LXOffset, AHexCellSize.Height div 2 );
  fVirtualBitmap.Canvas.LineTo( LPoint.X, LPoint.Y );
  // Line to point 5
  LPoint.Offset( -AHexCellSize.SmallWidth, 0 );
  fVirtualBitmap.Canvas.LineTo( LPoint.X, LPoint.Y );
  // Line to point 6
  LPoint.Offset( -LXOffset, -AHexCellSize.Height div 2 );
  fVirtualBitmap.Canvas.LineTo( LPoint.X, LPoint.Y );
  // Line to point 1
  LPoint.Offset( LXOffset, -AHexCellSize.Height div 2 );
  fVirtualBitmap.Canvas.LineTo( LPoint.X, LPoint.Y );
end;
function SE_Theater.GetHexDrawPoint( AHexCellSize : THexCellSize; ACol, ARow : Integer ) : TPoint;
begin
  Result.X := ( ( AHexCellSize.Width - AHexCellSize.SmallWidth ) div 2 + AHexCellSize.SmallWidth ) * ACol;
  Result.Y := AHexCellSize.Height * ARow + ( AHexCellSize.Height div 2 ) * ( ACol mod 2 );
end;

function SE_Theater.GetHexCellPoints( AOffSet : TPoint; AHexCellSize : THexCellSize; ACol, ARow : Integer ):TpointArray7;
var
  LPoint : TPoint;
  LXOffset : Integer;
begin
  LXOffset := ( AHexCellSize.Width - AHexCellSize.SmallWidth ) div 2;

  // Move to point 1
  LPoint := GetHexDrawPoint( AHexCellSize, ACol, ARow );
  LPoint.Offset( AOffSet );
  Result[0]:=Lpoint;
  // Line to point 2
  LPoint.Offset( AHexCellSize.SmallWidth, 0 );
  Result[1]:=Lpoint;
  // Line to point 3
  LPoint.Offset( LXOffset, AHexCellSize.Height div 2 );
  Result[2]:=Lpoint;
  // Line to point 4
  LPoint.Offset( -LXOffset, AHexCellSize.Height div 2 );
  Result[3]:=Lpoint;
  // Line to point 5
  LPoint.Offset( -AHexCellSize.SmallWidth, 0 );
  Result[4]:=Lpoint;
  // Line to point 6
  LPoint.Offset( -LXOffset, -AHexCellSize.Height div 2 );
  Result[5]:=Lpoint;
  // Line to point 1
  LPoint.Offset( LXOffset, -AHexCellSize.Height div 2 );
  Result[6]:=Lpoint;


end;


procedure SE_Engine.SetDestination(ASprite: SE_Sprite;  Destination: TPoint);
begin
  ASprite.FMoverData.FDestinationX := Destination.X;
  ASprite.FMoverData.FDestinationY := Destination.Y;
  ASprite.FMoverData.CalculateVectors(  );
end;
procedure SE_Engine.SortSprites;
begin
  FSortNeeded := true;
end;
procedure SE_Engine.SetVisible(const Value: boolean);
begin
  FVisible := Value;
end;

(*----------------------------------------------------------------------------------*)
(* Carica un Bitamp 24bit uncompressed da file impostando i parametri di animazione *)
(*----------------------------------------------------------------------------------*)
function SE_Engine.CreateSprite(const FileName,Guid: string; nFramesX, nFramesY, nDelay, posX, posY: integer; const Transparent: boolean  ): SE_Sprite;
var
aSprite: SE_Sprite;
begin
  aSprite:= SE_Sprite.Create ( Filename, Guid, nFramesX, nFramesY, nDelay, posX, posY, Transparent ) ;
  aSprite.Theater := FTheater;
  ASprite.FEngine := self;
//  PixelClick:= FTheater.PixelClick ;
  aSprite.OnDestinationreached := aSprite.iOnDestinationReached ;// aSpriteReachdestination;
  aSprite.Guid := Guid;

 // if (posX >= 0) and (posY >=0) then aSprite.Position :=  Point(posX,posY);

  lstNewSprites.Add( ASprite );
  aSprite.Visible := true;
  Result:= aSprite;
end;
(*---------------------------------------------------------------------------------------------*)
(* Carica un Bitamp 24bit uncompressed da un altro Bitmap impostando i parametri di animazione *)
(*---------------------------------------------------------------------------------------------*)
function SE_Engine.CreateSprite(const bmp: TBitmap; const Guid: string; nFramesX, nFramesY, nDelay, posX, posY: integer; const Transparent: boolean  ): SE_Sprite;
var
aSprite: SE_Sprite;
begin

  aSprite:= SE_Sprite.Create ( bmp, Guid, nFramesX, nFramesY, nDelay, posX, posY, Transparent ) ;
  aSprite.Theater := FTheater;
  ASprite.FEngine := self;
  aSprite.OnDestinationreached := aSprite.iOnDestinationReached ;// aSpriteReachdestination;
  aSprite.Guid := Guid;

//  if (posX >= 0) and (posY >=0) then aSprite.Position :=  Point(posX,posY);

  lstNewSprites.Add( ASprite );
  aSprite.Visible := true;
  Result:= aSprite;
end;
procedure SE_Engine.AddSprite(aSprite: SE_Sprite) ;
begin
  aSprite.Theater := FTheater;
  ASprite.FEngine := self;
  lstNewSprites.Add( ASprite );
  aSprite.Visible := true;
end;

procedure SE_Engine.CollisionDetection;
var
  i, k, x,y,L,T,vW,vH: integer;
  sprTrans, TargetTrans: TRGB;
  CollisionMatrix : SE_matrix;
//  CollisionArray: array of array of Integer;
  aTRGB: TRGB;
  f: byte;
  label NextSprite;
begin
 // Exit;
  if not Assigned( FOnCollision ) then Exit;

  for i := 0 to lstSprites.Count - 1 do  begin
        for k := i + 1 to lstSprites.Count - 1 do  begin
          if lstSprites[i].CollisionIgnore or lstSprites[k].CollisionIgnore then Continue;

          if lstSprites[i].DrawingRect.IntersectsWith(lstSprites[k].DrawingRect ) then begin
            if not FPixelCollision then begin

               FOnCollision( self, lstSprites[i], lstSprites[k] )
            end
            else begin
              if lstSprites[i].Transparent then begin
                sprTrans :=  lstSprites[i].GetTransparentcolor;
                TargetTrans := lstSprites[k].GetTransparentcolor;

                L:=lstSprites[i].DrawingRect.Left;
                T:=lstSprites[i].DrawingRect.Top;
                vW:=FTheater.VirtualWidth;
                vH:=FTheater.VirtualHeight;


              //  SetLength(CollisionArray, 0 , 0);
              //  SetLength(CollisionArray, vW , vH);

                CollisionMatrix := Se_Matrix.Create(vW,vH,1);
                {

                DstX :=  lstSprites[i].DrawingRect.Left;
                DstY :=  lstSprites[i].DrawingRect.Top;
                SrcX:=0;
                SrcY:=0;
                if DstX < 0 then begin
                  inc(SrcX, -DstX);
                  dec(RectWidth, -DstX);
                  DstX := 0;
                end;
                if DstY < 0 then begin
                  inc(SrcY, -DstY);
                  dec(RectHeight, -DstY);
                  DstY := 0;
                end;

                DstX := imin(DstX, FTheater.VirtualBitmap.Width - 1);
                DstY := imin(DstY, FTheater.VirtualBitmap.Height - 1);

                SrcX := imin(imax(SrcX, 0), lstSprites[i].FrameWidth - 1);
                SrcY := imin(imax(SrcY, 0), lstSprites[i].FrameHeight - 1);

                if SrcX + RectWidth > lstSprites[i].FrameWidth then
                  RectWidth := lstSprites[i].FrameWidth - SrcX;
                if SrcY + RectHeight > lstSprites[i].FrameHeight then
                  RectHeight := lstSprites[i].FrameHeight - SrcY;

                if DstX + RectWidth > FTheater.VirtualBitmap.Width then
                  RectWidth := FTheater.VirtualBitmap.Width - DstX;
                if DstY + RectHeight > FTheater.VirtualBitmap.Height then
                  RectHeight := FTheater.VirtualBitmap.Height - DstY;

                for y := 0 to RectHeight - 1 do begin
                  ppRGBCurrentFrame := lstSprites[i].FBMPCurrentFrame.GetSegment(SrcY + y, SrcX, RectWidth);
                  for x := SrcX to SrcX + RectWidth - 1 do begin
                    if (ppRGBCurrentFrame.b <> sprTrans.b) or (ppRGBCurrentFrame.g <> sprTrans.g) or (ppRGBCurrentFrame.r <> sprTrans.r) then begin
                      CollisionArray[  DstX + X , DstY + Y] := 1 ;
                    end;
                    inc(pbyte(ppRGBCurrentFrame),3);

                  end;
                end;  }

                 f:=1;
                for y := lstSprites[i].FrameHeight -1 downto 0 do begin
                  for x := lstSprites[i].FrameWidth -1 downto 0 do begin

                    aTRGB := lstSprites[i].FBMPCurrentFrame.Pixel24 [x,y];
                    if (aTRGB.b <> sprTrans.b ) or (aTRGB.g  <> sprTrans.g ) or (aTRGB.r  <> sprTrans.r ) then begin
                      if (L + X < 0)  or (L + X > vW)
                      or (T + Y < 0)  or (T + Y > vH)
                      then  Continue;
                      CollisionMatrix.Write(L+X,T+Y,f);
                  //    CollisionArray[L + X,T + Y]:= 1;
                    end;
                  end;
                end;


                // K
                {
                DstX :=  lstSprites[k].DrawingRect.Left;
                DstY :=  lstSprites[k].DrawingRect.Top;
                SrcX:=0;
                SrcY:=0;
                if DstX < 0 then  begin
                  inc(SrcX, -DstX);
                  dec(RectWidth, -DstX);
                  DstX := 0;
                end;
                if DstY < 0 then  begin
                  inc(SrcY, -DstY);
                  dec(RectHeight, -DstY);
                  DstY := 0;
                end;

                DstX := imin(DstX, FTheater.VirtualBitmap.Width - 1);
                DstY := imin(DstY, FTheater.VirtualBitmap.Height - 1);

                SrcX := imin(imax(SrcX, 0), lstSprites[k].FrameWidth - 1);
                SrcY := imin(imax(SrcY, 0), lstSprites[k].FrameHeight - 1);

                if SrcX + RectWidth > lstSprites[k].FrameWidth then
                  RectWidth := lstSprites[k].FrameWidth - SrcX;
                if SrcY + RectHeight > lstSprites[k].FrameHeight then
                  RectHeight := lstSprites[k].FrameHeight - SrcY;

                if DstX + RectWidth > FTheater.VirtualBitmap.Width then
                  RectWidth := FTheater.VirtualBitmap.Width - DstX;
                if DstY + RectHeight > FTheater.VirtualBitmap.Height then
                  RectHeight := FTheater.VirtualBitmap.Height - DstY;
               {
                for y := 0 to RectHeight - 1 do begin
                  ppRGBCurrentFrame := lstSprites[k].FBMPCurrentFrame.GetSegment(SrcY + y, SrcX, RectWidth);
                  for x := SrcX to SrcX + RectWidth - 1 do begin
                    if (ppRGBCurrentFrame.b <> TargetTrans.b) or (ppRGBCurrentFrame.g <> TargetTrans.g) or (ppRGBCurrentFrame.r <> TargetTrans.r) then begin
                      if CollisionArray[DstX + X , DstY + Y] = 1 then begin
                        FOnCollision( self, lstSprites[i], lstSprites[k] );
                        goto NextSprite;
                      end;
                    end;
                    inc(pbyte(ppRGBCurrentFrame),3);

                  end;
                end;
                }

                // qui sotto va come concetto ma non � performante.controllare sotto l'albero e poi ha smnesso di andare-

                 L:=lstSprites[k].DrawingRect.Left;
                 T:=lstSprites[k].DrawingRect.Top;

                for y := lstSprites[k].FrameHeight -1 downto 0 do begin
                  for x := lstSprites[k].FrameWidth -1 downto 0 do begin
                    aTRGB := lstSprites[k].FBMPCurrentFrame.Pixel24 [x,y];
                    if (aTRGB.b <> TargetTrans.b ) or (aTRGB.g  <> TargetTrans.g ) or (aTRGB.r  <> TargetTrans.r ) then begin

                      if (L + X < 0)  or (L + X > vW)
                      or (T + Y < 0)  or (T + Y > vH)
                      then  Continue;
                      CollisionMatrix.Read(L+X,T+Y,f);
//                      if CollisionArray[L + X,T + Y] = 1 then begin
                      if f = 1 then begin
                      
                        FOnCollision( self, lstSprites[i], lstSprites[k] );
                        CollisionMatrix.Free;
                        goto NextSprite;
                      end;

                    end;

                  end;
                end;
                CollisionMatrix.Free;
              end
              else FOnCollision( self, lstSprites[i], lstSprites[k] );
            end;
          end;
NextSprite:
        end;
  end;


end;

constructor SE_Engine.Create(AOwner: TComponent);
begin
  inherited Create( AOwner );

  lstSprites := TObjectList<SE_Sprite>.Create (true);
  lstNewSprites := TObjectList<SE_Sprite>.Create (false);

  lstEngines := TObjectList<SE_Engine>.Create (false);   // link a quella del theater
  FClickSprites := true;
  FVisible := true;

end;
destructor SE_Engine.Destroy;
begin
  Clear;
 // if FTheater <> nil then
//    FTheater.DetachSpriteEngine( self );
  lstNewSprites.free;
  lstSprites.Free;
  lstEngines.Free;
  inherited Destroy;
end;


procedure SE_Engine.RemoveSprite(ASprite: SE_Sprite);
begin
    ASprite.Dead := true;
end;



function SE_Engine.GetSpriteIndex(aSprite: SE_Sprite): integer;
var
i: integer;
begin
  result:=-1;
  for i := 0 to lstSprites.Count -1 do begin
    if  lstSprites[i] = aSprite then begin
      result:= i;
      Exit;
    end;
  end;

end;
Function SE_Engine.IsAnySpriteMoving :Boolean;
var
  i: integer;
begin
  Result := False;
  for i:= 0 to lstSprites.Count -1 do begin
    if (
      (lstSprites [i].MoverData.fDestinationX <> lstSprites [i].Position.X) or (lstSprites [i].MoverData.FDestinationY <> lstSprites [i].Position.Y)
      )
  and (
      (lstSprites [i].MoverData.SpeedX  <> 0) or  (lstSprites [i].MoverData.SpeedY <> 0)
      )

     then begin
//        OutputDebugString(PChar('ball moving ' +  IntToStr(lstSprites [i].Position.X) + '  ' + IntToStr(lstSprites [i].Position.Y)  ));
        result:=true;
        exit;
      end;
  end;

end;

Function SE_Engine.FindSprite (Guid: string):SE_sprite;
var
  i: integer;
begin
  Result:=nil;
  for i:= 0 to lstSprites.Count -1 do begin
    if lstSprites [i].Guid  = Guid then
      begin
        result:=lstSprites [i];
        exit;
      end;
  end;
  for i:= 0 to lstNewSprites.Count -1 do begin
    if lstNewSprites [i].Guid  = Guid then
      begin
        result:=lstNewSprites [i];
        exit;
      end;
  end;

end;
function SE_Engine.GetSprite(n: integer): SE_Sprite;
begin
  if n >= lstSprites.Count then
    Result := lstNewSprites[n - lstSprites.Count]
  else
    Result :=  lstSprites[n] ;
end;

function SE_Engine.GetSpriteCount: integer;
begin
  Result := lstSprites.Count + lstNewSprites.Count;
end;

procedure SE_Engine.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification( AComponent, Operation );
  if Operation = opRemove then
    if AComponent = FTheater then  FTheater := nil;
end;

procedure SE_Engine.ProcessSprites(interval: Integer);
var
  i, nIndex,L: integer;
begin

(* Ordinamento Sprites in base a priority *)
    if IsoPriority then begin

      for I := 0 to lstSprites.Count - 1 do  begin
         lstSprites[i].Priority :=  lstSprites[i].Position.Y +  lstSprites[i].ModPriority;
      end;

    end;
   FSortNeeded := false;
   lstSprites.sort(TComparer<SE_Sprite>.Construct(
   function (const L, R: SE_Sprite): integer
   begin
      result := trunc(L.Priority  - R.Priority  );
   end
  ));

  (* i nuovi sprite vanno nella lista principale *)


  while lstNewSprites.Count > 0 do  begin
    nIndex := -1;
    for i := 0 to lstSprites.Count - 1 do
      if  lstNewSprites[0].Priority <=  lstSprites[i].Priority then
      begin
        nIndex := i;
        Break;
      end;
    if nIndex = -1 then
      lstSprites.Add( lstNewSprites[0] )
    else

      lstSprites.Insert( nIndex, lstNewSprites[0] );
    lstNewSprites.Delete( 0 ); // <-- non libera l'oggetto, ha passato il puntatore
  end;

  // Movimento Sprites
  for i := 0 to lstSprites.Count - 1 do  begin
     lstSprites[i].Move(interval);
  end;
  // Rimuovo fli sprite morti (dead=true) dalla lista degli sprites
//  lstDeadSprites.Clear ;
  for i := lstSprites.Count - 1 downTo 0 do begin
    if lstSprites.Items [i].Dead then
      lstSprites.Delete(i);
  end;

  for i := lstSprites.Count - 1 downTo 0 do begin
    for L := lstSprites[i].Labels.Count - 1 downTo 0 do begin
      if lstSprites[i].Labels [L].Dead then
        lstSprites[i].Labels.Delete(L);
    end;
    for L := lstSprites[i].subSprites.Count - 1 downTo 0 do begin
      if lstSprites[i].subSprites [L].Dead then
        lstSprites[i].subSprites.Delete(L);
    end;
  end;

  {  while lstDeadSprites.Count > 0 do
  begin
    nIndex := lstSprites.IndexOf( lstDeadSprites[0] );
    if nIndex >= 0 then
    begin
      if Assigned( FOnRemoveSprite ) then  FOnRemoveSprite( self,  lstSprites[nIndex]  );
      lstSprites.Delete( nIndex );     // lo rimuove realmente

    end
    else
    begin
      nIndex := lstNewSprites.IndexOf( lstDeadSprites[0] );
      if nIndex >= 0 then
      begin
        //lstNewSprites[nIndex].Free;
        lstNewSprites.Delete( nIndex ); // non lo rimuove realmente
      end;
    end;

    lstDeadSprites.Delete( 0 );
  end;   }


end;

procedure SE_Engine.RemoveAllSprites;
var
  i: integer;
begin
  for i := lstSprites.Count - 1 downto 0 do
    RemoveSprite( Sprites[i] );
end;

procedure SE_Engine.RenderSprites;
var
  i: integer;
begin

//  if (Theater <> nil) and (lstSprites.Count > 0) then
  if (FVisible) and (Theater <> nil) then begin
    for i := 0 to lstSprites.Count - 1 do  begin
      lstSprites[i].SetCurrentFrame ;
     // application.ProcessMessages ;
      if lstSprites[i].Visible then lstSprites[i].Render ( FRenderBitmap );
     // application.ProcessMessages ;
    end;
  end;


end;


procedure SE_Engine.SetOnCollision(const Value: TCollisionEvent);
begin
  FOnCollision := Value;
end;

procedure SE_Engine.SetOnSpriteDestinationReached(const Value: SE_EngineEvent);
begin
  FOnSpriteDestinationReached := Value;
end;
procedure SE_Engine.SetPriority(const Value: integer);
begin

  FPriority := Value;
  if not (csDesigning in ComponentState) then
    if FTheater <> nil then  FTheater.SorTEngines;

end;


procedure SE_Engine.SetTheater(const Value: SE_Theater);
var
  i: integer;
begin
  FTheater := Value;
  if FTheater <> nil then  FTheater.AttachSpriteEngine( self );
  for i := 0 to lstSprites.Count - 1 do
    Sprites[i].FTheater := FTheater;
end;

procedure SE_Engine.Clear;
begin
    lstNewSprites.Clear;
    lstSprites.Clear ;
end;



constructor SE_Sprite.Create;
begin
  inherited create;
end;
constructor SE_Sprite.Create ( const FileName,Guid: string; const nFramesX, nFramesY, nDelay, posX,posY: integer; const TransparentSprite: boolean);
var
rectSource: TRect;
begin
  inherited create;
  Destinationreached := true;

  FAnimated := ( nFramesX > 1 ) ;//or ( FramesY > 1 );
  Self.guid:= Guid;
  SpriteFileName:=Filename;
  FMoverData:= SE_SpriteMoverData.Create;
  FMoverData.FSprite := self;

  lstLabels := Tobjectlist<SE_SpriteLabel>.create (True);
  lstSubSprites:= Tobjectlist<SE_SubSprite>.Create(True);

  fpause    :=false;

  FramesX  := nFramesX;
  FramesY  := nFramesY;
  FFrameXMin  := 0;
  FFrameXMax  := nFramesX;
  FAnimationInterval := nDelay;
  fDelay:=0;

  FBMP:= SE_Bitmap.Create(filename);   // carica il file
  FBMPCurrentFrame:=SE_Bitmap.Create (FBMP.Width div FramesX, FBMP.height div FramesY);
  FBMPalpha :=  SE_Bitmap.Create(FBMP.Width,FBMP.Height);   // crea un bmp alpha comunque
  FBMPCurrentFramealpha :=  SE_Bitmap.Create(FBMPCurrentFrame.Width,FBMPCurrentFrame.Height);   // crea un bmp alpha comunque

  fBmp.fbitmapAlpha := FBMPalpha.Bitmap ;
  fBmpCurrentFrame.fbitmapAlpha := FBMPCurrentFrameAlpha.Bitmap ;

  if (posX < 0) and (posY < 0 ) then  begin
    FPositionX := FBMPCurrentFrame.Width div 2;
    FPositionY := FBMPCurrentFrame.height div 2 ;
  end
  else begin
    FPositionX:= posX;
    FPositionY:= posY;
  end;

  //glielo devo passare gi� tagliato e poi andr� bene
    with rectSource do begin
      Left := 0;
      Top := 0;
      Right := ( FBMP.Width div FramesX)-1;
      Bottom :=( FBMP.Height div FramesY)-1;
    end;


  FBMP.CopyRectTo(fBMPCurrentFrame,RectSource.left,RectSource.top,0,0,RectSource.Width+1,RectSource.Height+1, false ,0 ) ;


  FFrameWidth := FBMPCurrentFrame.Width;
  FFrameHeight := FBMPCurrentFrame.height;

  FOnDestinationReached := iOnDestinationReached ;
  FOnDestinationReachedPerc := iOnDestinationReachedPerc ;


  Transparent := TransparentSprite;

end;

procedure SE_Sprite.ChangeBitmap ( const FileName: string; const nFramesX, nFramesY, nDelay: integer);
var
rectSource: TRect;
begin
  if bmp = nil then exit; // non ancora caricato

  while fchangingFrame do begin
    application.ProcessMessages ;
  end;

  fchangingBitmap:= True;
  SpriteFileName:=Filename;

  FramesX  := nFramesX;
  FramesY  := nFramesY;
  FAnimated := ( nFramesX > 1 ) ;//or ( FramesY > 1 );
  FFrameXMin  := 0;
  FFrameXMax  := nFramesX;
  FAnimationInterval := nDelay;
  //fDelay:=0;

  FBMP.LoadFromFileBMP(filename) ;
  fbmpCurrentFrame.Width := BMP.Width div FramesX;
  fbmpCurrentFrame.Height:= BMP.height div FramesY;

  FreeAndNil (FBMPalpha);
  FreeAndNil (FBMPCurrentFramealpha);
  FBMPalpha :=  SE_Bitmap.Create(FBMP.Width,FBMP.Height);   // crea un bmp alpha comunque
  FBMPCurrentFramealpha :=  SE_Bitmap.Create(FBMPCurrentFrame.Width,FBMPCurrentFrame.Height);   // crea un bmp alpha comunque


  FrameX := 0;
  FrameY := 0;

  //glielo devo passare gi� tagliato e poi andr� bene
    with rectSource do
    begin
      Left := 0;
      Top := 0;
      Right := ( FBMP.Width div FramesX)-1;
      Bottom :=( FBMP.Height div FramesY)-1;
    end;


   FBMP.CopyRectTo(fBMPCurrentFrame,RectSource.left,RectSource.top,0,0,RectSource.Width+1,RectSource.Height+1, false ,0 ) ;

  FFrameWidth := FBMPCurrentFrame.Width;
  FFrameHeight := FBMPCurrentFrame.height;

  fchangingBitmap:= false;

end;


constructor SE_Sprite.Create ( const bmp: Tbitmap; const Guid: string; const nFramesX, nFramesY, nDelay, posX,posY: integer; const TransparentSprite: boolean);
var
rectSource: TRect;
begin
  inherited create;
  Destinationreached := true;
  FAnimated := ( nFramesX > 1 ) ;//or ( FramesY > 1 );
  Self.Guid:= Guid;
  SpriteFileName:= 'TBitmap';
  FMoverData:= SE_SpriteMoverData.Create;
  FMoverData.FSprite := self;
  FPositionX:= posX;
  FPositionY:= posY;

  lstLabels := Tobjectlist<SE_SpriteLabel>.create (True);
  lstSubSprites:= Tobjectlist<SE_SubSprite>.Create(True);

  fpause    :=false;

  FramesX  := nFramesX;
  FramesY  := nFramesY;
  FrameXMin  := 0;
  FrameXMax  := nFramesX;
  FAnimationInterval := nDelay;
  fDelay:=0;


  FBMP:= SE_Bitmap.Create( bmp.width, bmp.height );
  FBMP.Assign(bmp);
  FBMPCurrentFrame:=SE_Bitmap.Create (FBMP.Width div FramesX , FBMP.height div FramesY );

  FBMPalpha :=  SE_Bitmap.Create(FBMP.Width,FBMP.Height);   // crea un bmp alpha comunque
  FBMPCurrentFramealpha :=  SE_Bitmap.Create(FBMPCurrentFrame.Width,FBMPCurrentFrame.Height);   // crea un bmp alpha comunque

  fBmp.fbitmapAlpha := FBMPalpha.Bitmap ;
  fBmpCurrentFrame.fbitmapAlpha := FBMPCurrentFrameAlpha.Bitmap ;

  //glielo devo passare gi� tagliato e poi andr� bene
    with rectSource do
    begin
      Left := 0;
      Top := 0;
      Right := ( FBMP.Width div FramesX)-1;
      Bottom :=( FBMP.Height div FramesY)-1;
    end;


 FBMPCurrentFrame.Bitmap.PixelFormat :=  pf24bit;

   FBMP.CopyRectTo(fBMPCurrentFrame,RectSource.left,RectSource.top,0,0,RectSource.Width+1,RectSource.Height+1,false  ,0) ;  //irargb

  FFrameWidth := FBMPCurrentFrame.Width;
  FFrameHeight := FBMPCurrentFrame.height;

  FOnDestinationReached := iOnDestinationReached ;
  FOnDestinationReachedPerc := iOnDestinationReachedPerc ;


  Transparent := TransparentSprite;


end;
procedure SE_Sprite.ChangeBitmap ( const  bmp: Tbitmap;  const nFramesX, nFramesY, nDelay: integer);
var
rectSource: TRect;
begin
  if bmp = nil then exit; // non ancora caricato

  while fchangingFrame do begin
    application.ProcessMessages ;
  end;
  fchangingBitmap:= True;

  FramesX  := nFramesX;
  FramesY  := nFramesY;
  FAnimated := ( nFramesX > 1 ) ;//or ( FramesY > 1 );
  FFrameXMin  := 0;
  FFrameXMax  := nFramesX;
  FAnimationInterval := nDelay;
//  fDelay:=0;

  FBMP.Assign(bmp);

  fbmpCurrentFrame.Width := BMP.Width div FramesX;
  fbmpCurrentFrame.Height:= BMP.height div FramesY;

  FreeAndNil (FBMPalpha);
  FreeAndNil (FBMPCurrentFramealpha);
  FBMPalpha :=  SE_Bitmap.Create(FBMP.Width,FBMP.Height);   // crea un bmp alpha comunque
  FBMPCurrentFramealpha :=  SE_Bitmap.Create(FBMPCurrentFrame.Width,FBMPCurrentFrame.Height);   // crea un bmp alpha comunque


  FrameX := 0;
  FrameY := 0;

  //glielo devo passare gi� tagliato e poi andr� bene
    with rectSource do begin
      Left := 0;
      Top := 0;
      Right := ( FBMP.Width div FramesX)-1;
      Bottom :=( FBMP.Height div FramesY)-1;
    end;


  FBMP.CopyRectTo(fBMPCurrentFrame,RectSource.left,RectSource.top,0,0,RectSource.Width+1,RectSource.Height+1, false ,0 ) ;

  FFrameWidth := FBMPCurrentFrame.Width;
  FFrameHeight := FBMPCurrentFrame.height;

  fchangingBitmap:= false;

end;



destructor SE_Sprite.Destroy;
begin

  FBMP.Free;
  FBMPCurrentFrame.Free;
  FBMPalpha.free;
  FBMPCurrentFrameAlpha.Free;
  FMoverData.free;
  lstLabels.Free;
  RemoveAllSubSprites;
  lstSubSprites.Free;
  inherited Destroy;
end;

procedure SE_Sprite.iOnDestinationReached;
var
X,Y: Single;
begin
  // internamente reached
  Destinationreached := true;
  if Theater.Grid <> gsNone then begin

    theater.UnMap( SE_Sprite(Self).Position.x  , SE_Sprite(Self).Position.Y, X,Y);

    fPositionCell.x:= Trunc(X ) ;
    fPositionCell.Y:= Trunc(Y);

  end;
  if NotifyDestinationReached then begin
    FNotifyDestinationReached:= false;
    if Assigned(FEngine.FOnSpriteDestinationReached) then FEngine.FOnSpriteDestinationReached(Self);
  end;

end;
procedure SE_Sprite.iOnDestinationReachedPerc;
begin
  // internamente reached
    DestinationreachedPerc := true;
    if NotifyDestinationReachedPerc then begin
      FNotifyDestinationReachedPerc:= false;
      if Assigned(FEngine.FOnSpriteDestinationReachedPerc) then FEngine.FOnSpriteDestinationReachedPerc(Self);
    end;
end;

function SE_Sprite.GetPosition: TPoint;
begin
  Result := Point( Trunc( PositionX ), Trunc( PositionY ) );
end;

function SE_Sprite.GetPositionX: single;
begin
  Result := FPositionX;
end;

function SE_Sprite.GetPositionY: single;
begin
  Result := FPositionY;
end;


procedure SE_Sprite.Move(interval: integer);
var
  temp: single;
  oldx, oldy: single;
  label endMove;

begin
  if LifeSpan > 0 then begin
    LifeSpan := LifeSpan - interval;
    if LifeSpan = 0 then  begin
      Dead := true;
      Exit;
    end;
  end;

  if AutoRotate then
  Angle := AngleOfLine ( position ,  MoverData.Destination );

  if FMoverData.UseMovePath then begin

     if FMoverData.curWP >= FMoverData.MovePath.Count -1 then  begin
       PositionX := FMoverData.MovePath[       FMoverData.MovePath.Count-1      ].X;
       PositionY := FMoverData.MovePath[       FMoverData.MovePath.Count-1      ].Y;
       FMoverData.UseMovePath := False;
       FMoverData.curWP := 0;//FMoverData.MovePath.Count-1;
       if NotifyDestinationReached  then
         if Assigned( FOnDestinationReached ) then FOnDestinationReached(  ); // <--- arriva su chi ha fatto l'override


       if NotifyDestinationReachedPerc  then begin
         if (FMoverData.curWP * 100) div ( FMoverData.MovePath.Count -1 ) >= FMoverData.reachPerc then begin
          if Assigned(FOnDestinationReachedPerc) then FOnDestinationReachedPerc(   );
         end;
       end;

       if fengine.FIsoPriority then Priority:= Position.Y + ModPriority;

     end
     else begin

       FMoverData.TWPinterval := FMoverData.TWPinterval - interval;
       if FMoverData.TWPinterval <= 0 then begin

         FMoverData.TWPinterval := FMoverData.WPinterval;
         FMoverData.curWP := FMoverData.curWP + Round(FMoverData.Speed) ;  // posso andare oltre. per qusto sotto devo fixare

         if FMoverData.curWP <= FMoverData.MovePath.Count-1 then begin
           PositionX := FMoverData.MovePath[FMoverData.curWP].X;
           PositionY := FMoverData.MovePath[FMoverData.curWP].Y;
         end
         else begin
           FMoverData.UseMovePath := False;
           FMoverData.curWP := 0;//FMoverData.MovePath.Count-1;
           if NotifyDestinationReached  then
             if Assigned( FOnDestinationReached ) then FOnDestinationReached(  ); // <--- arriva su chi ha fatto l'override
         end;
         if fengine.FIsoPriority then Priority:= Position.Y + ModPriority;
       end;
     end;


     Exit;
  end;



  // move normal

     if ( PositionX = FMoverData.fDestinationX ) and ( PositionY = FMoverData.fDestinationY ) then begin
       if Not NotifyDestinationReached  then Exit;
       if Assigned( FOnDestinationReached ) then FOnDestinationReached(  ); // <--- arriva su chi ha fatto l'override
       Exit;
     end;

    oldx :=  PositionX;
    oldy :=  PositionY;
//    if Guid = 'ball' then begin
//    OutputDebugString(PChar('ball ' +  FloatToStr(PositionX) + '  ' +  FloatToStr(PositionY) +'  ' +  FloatToStr(FMoverData.Speed)));
//    end;
    (*************************************************************************)
    (*                              X                                        *)
    (*************************************************************************)
    temp :=  PositionX + FMoverData.SpeedX;
    if ( FMoverData.SpeedX > 0 ) and ( temp > FMoverData.fDestinationX ) then
      PositionX := FMoverData.fDestinationX
    else if ( FMoverData.SpeedX < 0 ) and ( temp < FMoverData.fDestinationX ) then
      PositionX := FMoverData.fDestinationX
    else
      PositionX := PositionX + FMoverData.SpeedX;

    (*************************************************************************)
    (*                              Y                                        *)
    (*************************************************************************)
    temp := PositionY + FMoverData.SpeedY;
    if ( FMoverData.SpeedY > 0 ) and ( temp > FMoverData.fDestinationY ) then
      PositionY := FMoverData.fDestinationY
    else if ( FMoverData.SpeedY < 0 ) and ( temp < FMoverData.fDestinationY ) then
      PositionY := FMoverData.fDestinationY
    else
      PositionY := PositionY + FMoverData.SpeedY;

//    if Guid = 'ball' then
//    OutputDebugString(PChar('ball ' +  FloatToStr(PositionX) + '  ' +  FloatToStr(PositionY) +'  ' +  FloatToStr(FMoverData.Speed)));
//     if NotifyMoving then
//       if Assigned(engine.FOnSpriteMoving ) then engine.FOnSpriteMoving ( self  );

    if Assigned( FOnDestinationReached ) then
      if ( PositionX <> oldx ) or ( PositionY <> oldY ) then
                  if Not NotifyDestinationReached  then Exit;

    (* se reach � 80% o diversa da 0, calcolo se � arrivato *)
    if FMoverData.reachPerc <> 0 then begin
      if ( PositionX = FMoverData.fDestinationXreach ) and ( PositionY = FMoverData.fDestinationYreach ) then begin
    //          if Not NotifyDestinationReached then Exit;
        if Assigned(FOnDestinationReachedPerc) then FOnDestinationReachedPerc(   );
        if fengine.FIsoPriority then Priority:= Position.Y + ModPriority;
       // Exit;    // non arriva al 100%
      end;

    end;

    if ( PositionX = FMoverData.fDestinationX ) and ( PositionY = FMoverData.fDestinationY ) then begin
  //          if Not NotifyDestinationReached then Exit;
      if Assigned(FOnDestinationReached) then FOnDestinationReached(   );

    end;

   if fengine.FIsoPriority then Priority:= Position.Y + ModPriority;

end;


procedure SE_Sprite.SetAngle(const Value: single);
begin
  FAngle := -Value+90;    // <-- dipende da come � girato lo sprite in partenza
  //while a < 0 do
  //  a := a + 360;
  //while a >= 360 do
  //  a := a - 360;
 // FAngle := a;
end;
procedure SE_Sprite.SetTransparent(const Value: boolean);
begin
  FTransparent:= value;
end;


procedure SE_Sprite.SetDead(const Value: boolean);
begin
  if FDead <> Value then
  begin
    FDead := Value;
    if FDead then
    begin
      fVisible := false;
    end;
  end;
end;
function SE_Sprite.FindSubSprite ( Guid : string): SE_SubSprite;
var
  i: Integer;
begin
  Result:= nil;
  for I := 0 to lstSubSprites.Count -1  do begin
    if lstSubSprites[i].Guid = Guid then begin
      Result:= lstSubSprites[i];
      Exit;
    end;
  end;
end;
procedure SE_Sprite.DeleteSubSprite ( Guid : string);
var
  i: Integer;
begin
  for I := lstSubSprites.Count -1 downto 0  do begin
    if lstSubSprites[i].Guid = Guid then begin
      lstSubSprites[i].dead := true;
      lstSubSprites.Delete(i);
      Exit;
    end;
  end;
end;
procedure SE_Sprite.AddSubSprite ( aSubSprite : SE_SubSprite);
begin
  lstSubSprites.Add( aSubSprite );
end;
procedure SE_Sprite.RemoveAllSubSprites ;
var
  i: Integer;
begin
    for I := lstSubSprites.Count -1 downto 0  do begin
      lstSubSprites[i].dead := true;
      lstSubSprites.Delete(i);
    end;
end;

function SE_Sprite.CollisionDetect(aSprite: SE_sprite): Boolean;
var
  sprTrans,TargetTrans,aTRGB: TRGB;
  L,T,x,y: Integer;
  CollisionArray: array of array of Integer;

begin
  if DrawingRect.IntersectsWith(aSprite.DrawingRect ) then begin
    if not  FEngine.FPixelCollision then begin
       Result := True;
       Exit;
    end
    else begin
      if Transparent then begin
        sprTrans :=  GetTransparentcolor;
        TargetTrans := aSprite.GetTransparentcolor;

        L:=DrawingRect.Left;
        T:=aSprite.DrawingRect.Top;


        SetLength(CollisionArray, 0 , 0);
        SetLength(CollisionArray, FTheater.VirtualWidth , FTheater.VirtualHeight);


        // qui sotto va come concetto ma non � performante.controllare sotto l'albero e poi ha smnesso di andare-
        for y := FrameHeight -1 downto 0 do begin
       //   ppRGB := PRGB (lstSprites[i].FBMPCurrentFrame.fbitmapScanlines [y]);
          for x := FrameWidth -1 downto 0 do begin

            aTRGB := FBMPCurrentFrame.Pixel24 [x,y];
            if (aTRGB.b <> sprTrans.b ) or (aTRGB.g  <> sprTrans.g ) or (aTRGB.r  <> sprTrans.r ) then begin
  //                    if (ppRGB.b <> sprTrans.b ) or (ppRGB.g  <> sprTrans.g ) or (ppRGB.r  <> sprTrans.r ) then begin
              if (L + X < 0)  or (L + X > FTheater.VirtualWidth)
              or (T + Y < 0)  or (T + Y > FTheater.VirtualHeight)
              then  Continue;
              CollisionArray[L + X,T + Y]:= 1;
            end;
         // inc(pbyte(ppRGB), x * 3);
          end;
        end;

         L:=aSprite.DrawingRect.Left;
         T:=aSprite.DrawingRect.Top;

        for y := aSprite.FrameHeight -1 downto 0 do begin
          for x := aSprite.FrameWidth -1 downto 0 do begin
            aTRGB := aSprite.FBMPCurrentFrame.Pixel24 [x,y];
            if (aTRGB.b <> TargetTrans.b ) or (aTRGB.g  <> TargetTrans.g ) or (aTRGB.r  <> TargetTrans.r ) then begin

              if (L + X < 0)  or (L + X > FTheater.VirtualWidth)
              or (T + Y < 0)  or (T + Y > FTheater.VirtualHeight)
              then  Continue;
              if CollisionArray[L + X,T + Y] = 1 then begin
                Result := True;
                Exit;
              end;

            end;

          end;
        end;
      end
      else begin
        Result := True;
        Exit;
      end;
    end;

  end;
end;
procedure SE_Sprite.SetPositionCell(const Value: TPoint);
var
X,Y: Integer;
begin

  fPositionCell.X := Value.X;
  fPositionCell.Y := Value.Y;
  fTheater.Map( Trunc(Value.X), Trunc(Value.Y), true, X, Y  );

  PositionX:=X;
  PositionY:=Y;
  MoverData.Destination := Point (X,Y);

end;
procedure SE_Sprite.SetPosition(const Value: TPoint);
var
X,Y: Single;
begin
  fPosition := Value;
  PositionX := Value.X;
  PositionY := Value.Y;
  if Theater.grid <> gsNone then begin
    fTheater.unMap(Value.X,Value.Y, X,Y );
    FPositionCell.x:= Trunc(X);
    FPositionCell.y:= Trunc(Y);
  end;
end;

procedure SE_Sprite.SetPositionX(const Value: single);
begin
  fPosition.X := trunc(Value);
  FPositionX := Value;

end;

procedure SE_Sprite.SetPositionY(const Value: single);
begin
  fPosition.Y := Trunc(Value);
  FPositionY := Value;
end;
procedure SE_Sprite.SetAlpha(const Value: double);
begin
  falpha:= Value;
  if BMPAlpha <> Nil then begin
    BMPAlpha.Alpha:= fAlpha;
  end;
  if fBMPCurrentFrameAlpha <> Nil then begin
    fBMPCurrentFrameAlpha.Alpha:= fAlpha;
  end;


end;

procedure SE_Sprite.SetScale(const Value: integer);
begin
  FScale := Value;
end;
procedure SE_Sprite.SetBlendMode(const Value: SE_BlendMode);
begin
  FBlendMode := Value;
  FBMPcurrentFrame.BlendMode := FBlendMode;
end;
function SE_Sprite.getTransparentColor: TRGB;
begin
   if fTransparentForced  then begin
     Result:= TColor2TRGB (fTransparentColor);
   end
   else begin
     Result:= fBMPCurrentFrame.Pixel24   [0,0];
   end;
end;

procedure SE_Sprite.SetPriority(const Value: integer);
begin
  FPriority := Value;
  if FEngine <> nil then
    FEngine.SorTSprites;
end;

procedure SE_Sprite.SetFrameXmin (const Value: Integer);
begin
  if Value > 0 then begin
    FFrameXmin := Value;
    FFrameX := FFrameXmin;
  end;
end;

procedure SE_Sprite.SetFrameXmax (const Value: Integer);
begin
  if Value <= FframesX then FFrameXmax := Value;

end;

procedure SE_Sprite.SetCurrentFrame;
begin
  if fchangingBitmap then Exit;
  fchangingFrame:= True;

  if FAnimated then begin

      if fTheater.fUpdating or Pause = true then exit;
    //  if Guid='shahira' then asm int 3 end;

      Inc( fDelay );
      if fDelay >= AnimationInterval then  begin
        fDelay := 0;

        if AnimationDirection = dirForward then  begin
          Inc( FFrameX );
          if FFrameX > FFrameXMax -1 then begin   // <--- >= pu� saltare 1 frame e trovarsi a 358
           FFrameX := FramexMin;
         //  FFrameY := FFrameY + 1;
        //   if FFrameY > FramesY -1 then
        //    FFrameY:= 0;

             if StopAtEndX then begin
              FFrameX := FFrameXMax -1;
             end;
             if DieAtEndX then begin
              Dead:= True;
              exit;
             end;
             if HideAtEndX then begin
              fVisible:= False;
              exit;
             end;

          end;

       end

       else if AnimationDirection = dirBackward then begin
          Dec( FFrameX );
            if FFrameX < FFrameXMin then  begin
             FFrameX:= FFrameXMin;
          //   FFrameY := FramesY - 1;
          //   if FFrameY < 0 then
          //     FFrameY:= FFrameXMax;
             if StopAtEndX then begin
              FFrameX := FFrameXMin ;
             end;
             if DieAtEndX then begin
              Dead:= True;
              exit;
             end;
             if HideAtEndX then begin
              fVisible:= False;
              exit;
             end;

          end;
       end;

    end;
  end;


  DrawFrame;
  fchangingFrame:= false;

end;
procedure SE_Sprite.DrawFrame;
var
  rectSource : TRect;
  NewWidth, Newheight: integer;
begin
    with rectSource do
    begin
      Left := FrameX * BMP.Width div FramesX;
      Top := (FrameY-1) * BMP.Height div FramesY;
      Right := (Left + BMP.Width div FramesX)-1;
      Bottom :=( Top + BMP.Height div FramesY)-1;
    end;

     // reset
     if FFrameX > FFrameXMax -1 then
      FFrameX := FFrameXmin;
   //goto Myexit;   // <-- col cambio di bitmap pu� trovarsi oltre
   if not useBmpDimension then begin
    // FrameWidth := FBMP.Width div FramesX;
    // FrameHeight := FBMP.height div FramesY;
     fBmpCurrentFrame.Width := FrameWidth;     // <-- necessario in caso di Angle <> 0 oppure stretch reset iniziale
     fBmpCurrentFrame.Height := FrameHeight;   // <-- necessario in caso di Angle <> 0 oppure stretch reset iniziale
     if fBmpCurrentFrameAlpha <> nil then begin
       fBmpCurrentFrameAlpha.Width := FrameWidth;     // <-- necessario in caso di Angle <> 0 oppure stretch reset iniziale
       fBmpCurrentFrameAlpha.Height := FrameHeight;   // <-- necessario in caso di Angle <> 0 oppure stretch reset iniziale
     end;
   end
   else begin
     fBmpCurrentFrame.Width := Bmp.width ;
     fBmpCurrentFrame.Height := Bmp.height;
     if fBmpCurrentFrameAlpha <> nil then begin
       fBmpCurrentFrameAlpha.Width :=  Bmp.width;      // <-- necessario in caso di Angle <> 0 oppure stretch reset iniziale
       fBmpCurrentFrameAlpha.Height :=  Bmp.height;   // <-- necessario in caso di Angle <> 0 oppure stretch reset iniziale
     end;
   end;

   FBMP.CopyRectTo(fBMPCurrentFrame,RectSource.left,RectSource.top,0,0,RectSource.Width+1,RectSource.Height+1,false ,0) ;  //irargb tutorial 2!!! +1
   fBMPCurrentFrame.Alpha := Alpha;
   if Alpha <> 0 then
     FBMPAlpha.CopyRectTo(fBMPCurrentFrameAlpha,RectSource.left,RectSource.top,0,0,RectSource.Width+1,RectSource.Height+1,false ,0) ;  //demo tutorial 2!!! +1


  if fFlipped then begin
    fBmpCurrentFrame.Flip ( flipH );
   if Alpha <> 0 then
    fBmpCurrentFrameAlpha.Flip(fliph)
  end;
  if fAngle <> 0 then begin
    fBmpCurrentFrame.Rotate (fAngle);
   if Alpha <> 0 then
    fBmpCurrentFrameAlpha.Rotate (fAngle);
  end;
  if Scale <> 0 then begin
    NewWidth:= trunc (( fBmpCurrentFrame.Width * Scale ) / 100);
    NewHeight:= trunc (( fBmpCurrentFrame.Height * Scale ) / 100);
    if (NewWidth > 0) and (newheight > 0) then begin
      fBmpCurrentFrame.Stretch(NewWidth,NewHeight);
      if Alpha <> 0 then
      fBmpCurrentFrameAlpha.Stretch(NewWidth,NewHeight);
    end;
  end;
  if fGrayscaled then fBmpCurrentFrame.GrayScale ;



  DrawingRect := rect(Trunc( Position.X )  - fBmpCurrentFrame.Width div 2,
  Trunc( Position.Y ) -  fBmpCurrentFrame.height div 2,
  (Trunc(Position.X ) - fBmpCurrentFrame.Width div 2 ) + fBmpCurrentFrame.Width,
  (Trunc(Position.Y ) -  fBmpCurrentFrame.height div 2) + fBmpCurrentFrame.height);
  //DrawingRect := rect(Trunc( Position.X )  - FrameWidth div 2,
  //Trunc( Position.Y ) -  FrameHeight div 2,
  //(Trunc(Position.X ) - FrameWidth div 2 ) + BmpCurrentFrame.Width,
  //(Trunc(Position.Y ) -  FrameHeight div 2) + BmpCurrentFrame.height);

end;
procedure SE_Sprite.Render ( RenderTo: TRenderBitmap );
var

  i,y,X: integer;


  wTrans: dword;
  aTrgb: Trgb;
  diff,textwidth: Integer;
  DestBitmap: SE_Bitmap;
begin

    

    if RenderTo = VisibleRender then
      DestBitmap:= Theater.VisibleBitmap else
        DestBitmap := Theater.fvirtualBitmap;



  X:= DrawingRect.Left ;
  Y:= DrawingRect.top;

  // gestione subsprites
   for I := 0 to lstSubSprites.Count -1 do begin
      if lstSubSprites.Items [i].LifeSpan > 0 then  begin
        lstSubSprites.Items [i].LifeSpan := lstSubSprites.Items [i].LifeSpan -  FTheater.thrdAnimate.Interval ;
        if lstSubSprites.Items [i].LifeSpan <= 0 then begin
           lstSubSprites.Items [i].Dead := true;
        end;
      end;

    if (lstSubSprites [i].lVisible) and not (lstSubSprites.Items [i].Dead) then begin

      lstSubSprites [i].lBmp.CopyRectTo(fBMPCurrentFrame,0,0,
                              lstSubSprites [i].lx,lstSubSprites [i].ly,
                              lstSubSprites [i].lBmp.Width , lstSubSprites [i].lBmp.Height ,
                              lstSubSprites [i].ltransparent, lstSubSprites [i].lBmp.Bitmap.Canvas.Pixels [0,0]);
    end;
   end;
  // fine gestione subsprites

  // labels

   for I := 0 to lstLabels.Count -1 do begin

    if lstLabels.Items [i].LifeSpan > 0 then  begin
      lstLabels.Items [i].LifeSpan := lstLabels.Items [i].LifeSpan - FTheater.thrdAnimate.Interval ;
      if lstLabels.Items [i].LifeSpan = 0 then begin
         lstLabels.Items [i].Dead := true;
      end;
    end;


    if (lstLabels.Items [i].lVisible) and not (lstLabels.Items [i].Dead)  then begin


      fBMPCurrentFrame.Canvas.Font.Assign( lstLabels.Items[i].lFont );
      fBMPCurrentFrame.Canvas.pen.mode := lstLabels.Items[i].lpenmode ;
      fBMPCurrentFrame.Canvas.pen.Color :=  fBMPCurrentFrame.Canvas.Font.Color;
      fBMPCurrentFrame.Canvas.Brush.Style := bsClear;
      fBMPCurrentFrame.Canvas.Font.Quality :=  fqAntialiased;

      if lstLabels.Items[i].lX =-1 then begin    // -1 Center X
          textWidth:=fBMPCurrentFrame.Canvas.TextWidth(lstLabels.Items[i].lText) ;
          Diff := ((FFrameWidth - textWidth) div 2);
          fBMPCurrentFrame.Canvas.TextOut ( diff ,
          lstLabels.Items[i].lY, lstLabels.Items[i].lText  ) ;

      end
      else
      fBMPCurrentFrame.Canvas.TextOut(lstLabels.Items[i].lX , lstLabels.Items[i].lY, lstLabels.Items[i].lText  ) ;


    end;
   end;



   if Transparent then begin

     if fTransparentForced  then begin
       aTRGB:= TColor2TRGB (fTransparentColor);
       wTrans:= fTransparentColor
     end
     else begin
       aTRGB:= fBMPCurrentFrame.Pixel24   [0,0];
       wtrans:=    RGB2TColor (aTRGB.r, aTRGB.g , aTRGB.b) ;
     end;
   end;


    fBmpCurrentFrame.fbitmapAlpha := FBMPCurrentFrameAlpha.Bitmap ;
    fBmpCurrentFrame.CopyRectTo( DestBitmap,0,0,X,Y,fBmpCurrentFrame.Width+1, fBmpCurrentFrame.height+1,Transparent,wtrans ) ;


end;
procedure SE_Sprite.MakeDelay(msecs: integer);
var
  FirstTickCount: longint;
begin
  FirstTickCount := GetTickCount;
   repeat
     Application.ProcessMessages;
   until ((GetTickCount-FirstTickCount) >= Longint(msecs));
end;
procedure SE_Theater.Loaded;
begin
  inherited;
  lstSpritesHandled := True;
  if not (csDesigning in ComponentState) then begin
    if Not Passive then begin
      thrdAnimate := SE_ThreadTimer.Create(self);
     //thrdAnimate.KeepAlive := True;
      thrdAnimate.Interval := 20;
      thrdAnimate.OnTimer :=  OnTimer ;
     // Active := true;
    end;
  end;
end;
constructor SE_Theater.Create(Owner: TComponent);
begin

  inherited Create(Owner);

  fZoom := 100;
  fZoomDiv100 := fZoom / 100;
  f100DivZoom := 100 / fZoom;
  fOffsetX := 0;
  fOffsetY := 0;
  fPaintWidth := 0;
  fPaintHeight := 0;

  fUpdating := true;

  Height := 212;
  Width := 212;
  fVirtualWidth:= Width;
  fVirtualHeight:= Height;

  if (csDesigning in ComponentState) then begin

    fMouseScrollRate := 1.00;
    fMouseWheelInvert := false;
    fMouseWheelValue := 10;
    FMouseWheelZoom := true;
    FMousePan := true;
    MouseScroll:= false;

    FAnimationInterval :=20;

    FGridInfoCell := false;
    FGridVisible:= false;
    FGrid := gsnone;
    FGridColor := clsilver;
    FCellWidth := 40;
    FCellHeight :=30;
    FCellsX := 10;
    FCellsY := 4;
    FHexSmallWidth :=10;

    AHexCellSize.Width := FCellWidth;
    AHexCellSize.Height:= FCellHeight;
    aHexCellSize.SmallWidth := fHexSmallwidth;

  end
  else begin
    fVisibleBitmap := SE_Bitmap.Create(width, height);
    fVirtualBitmap := SE_Bitmap.Create(width, height);
    lstSpriteClicked:= TObjectList<SE_Sprite>.Create(false); // false o ad ogni clear distrugge gli sprite
    lstSpriteMoved:= TObjectList<SE_Sprite>.Create(false);
    lsTEngines := TObjectList<SE_Engine>.Create(true);
  end;

    fUpdating:=false;

end;

destructor SE_Theater.Destroy;
var
i: integer;
begin

  if not (csDesigning in ComponentState) then  begin
    if not Passive then begin
      FActive := false;
      thrdAnimate.Enabled := False;
      thrdAnimate.Free;
    end;
    for i := lstEngines.Count - 1 downto 0 do
    begin
      lstEngines[i].RemoveAllSprites ;
      DetachSpriteEngine(lstEngines[i]);
    end;

    FreeAndNil(fVisibleBitmap);
    FreeAndNil(fVirtualBitmap);
    lstSpriteClicked.free;
    lstSpriteMoved.Free;
    lsTEngines.free;
  end;

  inherited;
end;


procedure SE_Theater.SetBackColor(const aColor: TColor);
begin
  fbackColor:= aColor;
 // if csDesigning in ComponentState then  Clear;
  Update;

end;


procedure SE_Theater.SetCellsX (const v: integer);
begin
  FCellsX := v;
end;
procedure SE_Theater.SetCellsY (const v: integer);
begin
    FCellsY := v;
end;
procedure SE_Theater.SetCollisionDelay(const nDelay: integer);
begin
  if nDelay > 0 then begin
    fCollisionDelay := nDelay;
    iCollisionDelay := nDelay;
  end;
end;
procedure SE_Theater.SetGridStyle(const aGridStyle: TGridStyle);
begin
  fGrid:= aGridStyle;
end;
procedure SE_Theater.SetCellWidth (const v: integer);
begin
  FCellWidth := v;
  if FGrid  = gsHex then begin

    AHexCellSize.Width := v;

  end;
end;
procedure SE_Theater.SetCellHeight (const v: integer);
begin
  FCellHeight := v;
  if FGrid  = gsHex then begin

    AHexCellSize.Height:= v;

  end;
end;
procedure SE_Theater.SetHexSmallWidth (const v: integer);
begin
  if FGrid  = gsHex then begin

    fHexSmallWidth:=v;
    aHexCellSize.SmallWidth := v;

  end;
end;
procedure SE_Theater.Clear;
begin

  //Canvas.Fill( fBackground );
  Canvas.Brush.Color := fBackColor;
  Canvas.Brush.Style := bsSolid;
  Canvas.FillRect(Rect(0,0,Width,Height));
  Update;
end;


procedure SE_Theater.SetVirtualWidth(const v: integer);
begin

  fvirtualWidth := v;
  if fVirtualheight <= 0 then exit;
  if not (csDesigning in ComponentState) then  begin
  //if not FActive then exit;
  if  (csLoading in ComponentState) then Exit;
    if not Passive then
      Active:= false;
    //FreeAndNil( fVirtualBitmap );
    fVirtualBitmap.Free;
    fVirtualBitmap:= SE_Bitmap.Create(fvirtualwidth, fvirtualheight);
    update;
    if not Passive then
     Active:= true;
  end;


end;
procedure SE_Theater.SetVirtualHeight(const v: integer);
begin

  fvirtualheight := v;
  if fVirtualHeight <= 0 then exit;

  if not (csDesigning in ComponentState) then begin
  //  if not FActive then exit;
  if  (csLoading in ComponentState) then Exit;
    if not Passive then
      Active:= false;
    fVirtualBitmap.Free;
    fVirtualBitmap:= SE_Bitmap.Create(fvirtualwidth, fvirtualheight);
    update;
    if not Passive then
      Active:= true;
  end;


end;

procedure SE_Theater.CenterTheater;
begin
  SetViewXY(trunc((fVirtualBitmap.Width*fZoomDiv100 - ClientWidth)/2), trunc((fVirtualBitmap.Height*fZoomDiv100 - ClientHeight)/2));
end;


function SE_Theater.GetVisibleBitmapRect : TRect;
begin
  Result.Left   := XVisibleToVirtual( OffsetX );
  Result.Top    := YVisibleToVirtual( OffsetY );
  Result.Right  := XVisibleToVirtual( Width - OffsetX ) - 1;
  Result.Bottom := YVisibleToVirtual( Height - OffsetY ) - 1;
end;


procedure SE_Theater.ResetState();
begin
  Zoom := 100.0;
  ViewX := 0;
  ViewY := 0;
  Update();
end;


procedure SE_Theater.GetPaintCoords(var XSrc, YSrc, SrcWidth, SrcHeight: integer; var DstWidth, DstHeight: integer; tViewX, tViewY: integer);
var
  rr: double;
begin
  XSrc := 0;
  SrcWidth := 0;
  YSrc := 0;
  SrcHeight := 0;
  if ZoomWidth <> 0 then
  begin
    rr := fVirtualWidth / ZoomWidth;
    XSrc := round(tViewX * rr);
    SrcWidth := round(fPaintWidth * rr);
    if (XSrc + SrcWidth) > fVirtualWidth then
      dec(SrcWidth);
  end;
  if ZoomHeight <> 0 then
  begin
    rr := fVirtualHeight / ZoomHeight;
    YSrc := round(tViewY * rr);
    SrcHeight := round(fPaintHeight * rr);
    if (YSrc + SrcHeight) > fVirtualHeight then
      dec(SrcHeight);
  end;
  if Zoom > 100 then
  begin
    DstWidth := trunc(SrcWidth * fZoomDiv100);
    DstHeight := trunc(SrcHeight * fZoomDiv100);

    if (DstWidth < fPaintWidth) and (XSrc + SrcWidth  <= fVirtualWidth) then
    begin
      inc(SrcWidth);
      DstWidth := trunc(SrcWidth * fZoomDiv100);
    end;
    if (DstHeight < fPaintHeight) and (YSrc + SrcHeight  <= fVirtualHeight) then
    begin
      inc(SrcHeight);
      DstHeight := trunc(SrcHeight * fZoomDiv100);
    end;

  end
  else begin
    DstWidth := fPaintWidth;
    DstHeight := fPaintHeight;
  end;
end;

procedure SE_Theater.SetViewX(v: integer);
var
  max_x, max_y: integer;
  lviewx: Integer;
begin
  if v = fViewX then
    exit;
  lviewx := fViewX;
  GetMaxViewXY(max_x, max_y);
  fViewX := ilimit(v, 0, max_x);
  if fViewX=lviewx then
    exit;
end;


procedure SE_Theater.SetViewY(v: integer);
var
  max_x, max_y: integer;
  lviewy: Integer;
begin
  if v = fViewY then
    exit;
  lviewy := fViewY;
  GetMaxViewXY(max_x, max_y);
  fViewY := ilimit(v, 0, max_y);
  if fViewY=lviewy then
    exit;
end;

procedure SE_Theater.GetMaxViewXY(var mx, my: integer);
var
  deltax, deltay: integer;
begin

    deltax := trunc(VirtualWidth * fZoomDiv100);
    deltay := trunc(VirtualHeight * fZoomDiv100);
    if ((deltax > (Width)) or (deltay > (Height ))) then begin
      deltax := trunc((VirtualWidth+1) * fZoomDiv100);
      deltay := trunc((VirtualHeight+1) * fZoomDiv100);
    end;
    mx := 0;
    my := 0;
    if (deltax > 0) and (deltay > 0) then begin
      mx := deltax - Width;
      my := deltay - Height;
      if (mx < 0) or (XVisibleToVirtual(mx) = 0) then
        mx := 0;
      if (my < 0) or (YVisibleToVirtual(my) = 0) then
        my := 0;
      if (deltax <= Width) and (deltay <= Height) then begin
        mx := 0;
        my := 0;
      end;
    end;
end;

function SE_Theater.XVirtualToVisible(x: integer): integer;
begin
    result := round(fOffsetX + (x + round((-fViewX) * f100DivZoom)) * fZoomDiv100);
end;

function SE_Theater.YVirtualToVisible(y: integer): integer;
begin
    result := round(fOffsetY + (y + round((-fViewY) * f100DivZoom)) * fZoomDiv100);
end;

function SE_Theater.XVisibleToVirtual(x: integer): integer;
begin
    result := trunc((X - fOffsetX) * f100DivZoom + VirtualSource1x);
end;
function SE_Theater.YVisibleToVirtual(y: integer): integer;
begin
    result := trunc((Y - fOffsetY) * f100DivZoom + VirtualSource1y);
end;

procedure SE_Theater.ZoomAt(x, y: integer; ZoomVal: double);
var
  zz: double;
  bx, by: Integer;
begin
  fUpdating:=true;
  bx := XVisibleToVirtual(x);
  by := YVisibleToVirtual(y);

  Zoom := ZoomVal;
  zz := Zoom / 100;

  SetViewXY(trunc(bx*zz - x +Zoom/100), trunc(by*zz - y+Zoom/100));

  fUpdating:=false;

  GetPaintCoords(VirtualSource1x, VirtualSource1y, VirtualSourceWidth, VirtualSourceHeight, fDstX, fDstY, fViewX, fViewY);

end;

procedure SE_Theater.ZoomIn;
begin
  Zoom := GetNextZoomValue(Zoom, True, dmin(Width / (Width / 100), Height / (Height / 100)));
end;

procedure SE_Theater.ZoomOut;
begin
  Zoom := GetNextZoomValue(Zoom, False, dmin(Width / (Width / 100), Height / (Height / 100)));
end;


procedure SE_Theater.Update;
begin
  if (csDesigning in ComponentState) then
    exit;
  if (ComponentState <> []) and (ComponentState <> [csDesigning]) and (ComponentState <> [csFreeNotification]) then
    exit;

  fUpdating := true;
  // lo zoom aumenta o diminuisce le dimensioni del bitmap
  ZoomWidth := round(VirtualWidth * fZoomDiv100);
  ZoomHeight := round(VirtualHeight * fZoomDiv100);
  fOffsetX := 0;
  fOffsetY := 0;
  if not (csDesigning in ComponentState) then
  begin
    fPaintWidth := imin(ZoomWidth, Width);
    fPaintHeight := imin(ZoomHeight, Height);

    // se ho zoommato molto IN l'immagine � pi� piccola. Devo spsostare l'offset fino a centrare l'immagine
    // il BackColor riempe lo spazio irrisolto.
    if (fPaintWidth < Width) then
        fOffsetX := (Width - fPaintWidth) div 2;

    if (fPaintHeight < Height) then
    fOffsetY := (Height - fPaintHeight) div 2;

  end
  else
  begin
    fPaintWidth := imin(ZoomWidth, Width);
    fPaintHeight := imin(ZoomHeight, Height);
  end;


  fUpdating := false;
end;

procedure SE_Theater.SaveInfoZoom(v: double);
var
  zz: double;
  max_x, max_y: integer;
  x, y: integer;
begin
  // per non calcolare ogni volta salvo le informazioni di zoom attuale
  zz := v / 100;
  x := Width shr 1;
  x := trunc(round((x + fViewX - fOffsetX) * (f100DivZoom)) * zz - x);
  y := Height shr 1;
  y := trunc(round((y + fViewY - fOffsetY) * (f100DivZoom)) * zz - y);

  fZoom := v;
  fZoomDiv100 := fZoom / 100;
  f100DivZoom := 100 / fZoom;


  GetMaxViewXY(max_x, max_y);
  fViewX := ilimit(x, 0, max_x);
  fViewY := ilimit(y, 0, max_y);
end;


procedure SE_Theater.SetZoom(v: double);
begin
  if (v > 0) and ((v <> fZoom) or (v<>fZoom)) then  begin
    fUpdating:= true;
    SaveInfoZoom(v);
    Update;
    GetPaintCoords(VirtualSource1x, VirtualSource1y, VirtualSourceWidth, VirtualSourceHeight, fDstX, fDstY, fViewX, fViewY);
    fUpdating:= false;
  end;
end;

procedure SE_Theater.DoMouseWheelScroll(Value, X, Y: integer);
var
  direction: integer;
begin
  if not fMouseWheelZoom then exit;

  if Value > 0 then
    direction := 1
  else
    direction := -1;
  if fMouseWheelInvert then
    direction := -1 * direction;

    ZoomAt(X, Y, fZoom + imax(round(fZoom * fMouseWheelValue / 100), 1) * direction);
end;

procedure SE_Theater.WMMouseWheel(var Message: TMessage);
var
  pt: TPoint;
begin
  inherited;
  pt.x := smallint(Message.LParamLo);
  pt.y := smallint(Message.LParamHi);
  pt := ScreenToClient(pt);
  DoMouseWheelScroll(smallint($FFFF and (Message.wParam shr 16)), pt.x, pt.y);
end;

procedure SE_Theater.WMSize(var Message: TWMSize);
begin
  inherited;
  if not fUpdating then  Update;
end;

procedure SE_Theater.WMEraseBkgnd(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure SE_Theater.SetViewXY(x, y: integer);
var
  max_x, max_y: integer;
begin
  if (x = fViewX) and (y = fViewY) then
    exit;
  GetMaxViewXY(max_x, max_y);
  fViewX := ilimit(x, 0, max_x);
  fViewY := ilimit(y, 0, max_y);
end;


procedure SE_Theater.PaintVisibleBitmap ( Interval: integer);
var
  i: integer;
begin

    if assigned (FBeforeVisibleRender) then
      FBeforeVisibleRender (Self, fVirtualBitmap, fVisibleBitmap );

      fVisibleBitmap.Allocate( Width, Height);   // <--- importante nel caso di resize virtualwidth e virtualheight
      FinalPaint(fVisibleBitmap, fVisibleBitmap.TBitmapScanlines);

    if assigned (FAfterVisibleRender) then
      FAfterVisibleRender (Self, fVirtualBitmap, fVisibleBitmap );

    // render su VisibleBitmap degli engines
    for i := lstEngines.Count - 1 downto 0 do begin
      if lstEngines.items[i].RenderBitmap = VisibleRender then begin
        lstEngines.items[i].ProcessSprites(GetTickCount - Interval  );
        lstEngines.items[i].RenderSprites;
      end;
    end;


    if ShowPerformance then
    begin
      if GetTickCount > nPerformanceEnd then
      begin
        nPerformanceEnd := GetTickCount + 1000;
        nShowFrames := nFrames;
        nFrames := 0;
      end;
      VisibleBitmap.Canvas.Brush.Color := clWhite;
      VisibleBitmap.Canvas.Brush.Style := bsSolid;
      VisibleBitmap.Canvas.Font.Assign( self.Font );
      VisibleBitmap.Canvas.TextOut( 4, 4, IntToStr( nShowFrames ) );
    end;
    {$IFDEF NAGSCREEN }
      VisibleBitmap.Canvas.Brush.Color := clYellow;
      VisibleBitmap.Canvas.Brush.Style := bsSolid;
      VisibleBitmap.Canvas.Font.Assign( self.Font );
      VisibleBitmap.Canvas.TextOut( 25, 4, 'Demo version' ) ;
    {$ENDIF NAGSCREEN }

   // qui copia da fVisibleBitmap al canvas
  //        DIB_SectionHandle: HBITMAP;
    BitBlt(Canvas.Handle, 0, 0, Width, Height, fVisibleBitmap.Canvas.Handle, 0, 0, SRCCOPY);
    //    StretchDIBits(Canvas.Handle, 0, 0, dx, dy,
    //      0, 0, Width, Height, VisibleBitmap.fData, VisibleBitmap.info, DIB_RGB_COLORS, SRCCOPY);

end;




procedure SE_Theater.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited;
  if (csReading in ComponentState) or (csDesigning in ComponentState) or (csLoading in ComponentState) then
    if assigned(fVisibleBitmap) then begin
      fVisibleBitmap.Width := Width;
      fVisibleBitmap.Height := Height;
   //   Clear;
    end;
end;

procedure SE_Theater.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i: integer;
  tmpX, tmpY: Single;
  ParForm: TCustomForm;
  s: integer;
  spr: SE_Sprite;
  pt: TPoint;
  BmpX,BmpY: integer;
begin
  inherited;
  ParForm := GetParentForm(Self);
  if (ParForm<>nil) and (ParForm.Visible) and CanFocus then
    SetFocus;

//  if mouseWheelZoom = true  then  begin

    fMouseDownX := x;
    fMouseDownY := y;
    fLastMouseMoveX := x;
    fLastMouseMoveY := y;
    MouseDownViewX := ViewX;
    MouseDownViewY := ViewY;
//  end;

  pt := Point( XVisibleToVirtual(x), YVisibleToVirtual(y) );
  // Theater MouseUp


  // normal
  if Assigned( FOnmousedown )  then  FOnmousedown( self, Button, Shift, X, Y );
  //spriteclick


  lstSpriteClicked.clear;
    for i := lstEngines.Count - 1 downTo 0 Do  begin

      if not lstEngines[i].ClickSprites then  Continue;
      if lstEngines[i].RenderBitmap = VisibleRender then begin
        pt.X:=X; // rimetto gli originali X Y
        pt.Y:=Y;
      end
      else
      begin    // ogni volta devo ribadire
        pt := Point( XVisibleToVirtual(x), YVisibleToVirtual(y) );
      end;
      for s := lstEngines[i].lstSprites.Count - 1 downto 0 do begin
        spr := lstEngines[i].Sprites[s];
        if spr.Visible then
        begin
          if spr.DrawingRect.Contains ( pt ) then begin
            bmpX:= spr.DrawingRect.Right  - pt.X    ; // <--- sul virtualBitmap
            bmpX:= spr.DrawingRect.Width - bmpX;
            bmpY:= spr.DrawingRect.bottom - pt.Y;
            bmpY:= spr.DrawingRect.Height - bmpY;
            Spr.MouseX := bmpX;
            Spr.MouseY := bmpY;
            if spr.Transparent then begin          // Transaprent
              if lstEngines[i].PixelClick then begin
                if spr.fBMPCurrentFrame.Canvas.Pixels [BmpX,BmpY] <> spr.fBMPCurrentFrame.Canvas.Pixels [0,0] then begin
                  if ( lstEngines[i].ClickSprites)
                    then lstSpriteClicked.Add(spr);
                end;
              end
              else begin
                if ( lstEngines[i].ClickSprites)
                  then lstSpriteClicked.Add(spr);
              end;
            end
            else begin  // no transparent
//                bmpX:= spr.DrawingRect.Right  - pt.X    ; // <--- sul virtualBitmap
//                bmpX:= spr.DrawingRect.Width - bmpX;
//                bmpY:= spr.DrawingRect.bottom - pt.Y;
//                bmpY:= spr.DrawingRect.Height - bmpY;
                 if ( lstEngines[i].ClickSprites)
                  then lstSpriteClicked.Add(spr); //<-- spr.MouseDown pu� disabilitare spriteclick
            end;
          end;
        end;

      end;
    end;


    if Assigned( FOnSpritemousedown ) and (lstSpriteClicked.Count > 0)  then
      FOnSpritemousedown( self, lstSpriteClicked , Button, Shift );

  // cells
  if Assigned( FOnCellMouseDown ) then begin
    pt := Point( XVisibleToVirtual(x), YVisibleToVirtual(y) );
    UnMap (pt.x,pt.y, tmpX, tmpY);
    FOnCellMouseDown( self, Button, Shift, Floor(tmpX), Floor(tmpY) );
  end;

  if Assigned(  FOnTheaterMouseDown ) then begin
    FOnTheaterMouseDown( self, X, Y, pt.X, pt.Y,Button,Shift);
  end;

end;



procedure SE_Theater.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  lastx, lasty: integer;
  tmpX, tmpY: Single;
  cx, cy: Integer;
  max_x, max_y: Integer;
  i, s, BmpX,BmpY: integer;
  spr: SE_Sprite;
  pt: TPoint;
  Label NoSprites;
begin
  inherited;
  if changeCursor then cursor := crDefault;

  lastx := x;
  lasty := y;

  if MouseCapture then begin
    if MousePan then // panning
      SetViewXY(MouseDownViewX - trunc((lastx - fMouseDownX)*fMouseScrollRate), MouseDownViewY - trunc((lasty - fMouseDownY)*fMouseScrollRate) ); // 3.0.2
  end;

  if (MouseScroll ) and ((fLastMouseMoveX<>lastx) or (fLastMouseMoveY<>lasty)) and not MouseCapture then  begin
    GetMaxViewXY(max_x, max_y);
    cx := trunc( (imax(imin(Width -1, lastx), 0)/(Width ))  * (max_x) );
    cy := trunc( (imax(imin(Height-1, lasty), 0)/(Height))  * (max_y) );
    SetViewXY( cx, cy );
  end;

  fLastMouseMoveX := lastx;
  fLastMouseMoveY := lasty;
  pt := Point( XVisibleToVirtual(x), YVisibleToVirtual(y) );



  // normal
  if Assigned( FOnMouseMove ) then
    FOnMouseMove( self, Shift,  X ,  Y  );
  // Spritemousemove

  if not lstSpritesHandled then goto noSprites; // se la precedente list non � ancora stata gestita
    lstSpriteMoved.Clear ;

    for i := lstEngines.Count - 1 downTo 0 Do  begin
      if not lstEngines[i].ClickSprites then
        Continue;
      if lstEngines[i].RenderBitmap = VisibleRender then begin
        pt.X:=X; // rimetto gli originali X Y
        pt.Y:=Y;
      end
      else
      begin    // ogni volta devo ribadire
        pt := Point( XVisibleToVirtual(x), YVisibleToVirtual(y) );
      end;
      for s := lstEngines[i].lstSprites.Count - 1 downto 0 do begin
        spr := lstEngines[i].Sprites[s];
        if spr.Visible then  begin
          if spr.DrawingRect.Contains ( pt ) then begin
            bmpX:= spr.DrawingRect.Right  - pt.X    ; // <--- sul virtualBitmap
            bmpX:= spr.DrawingRect.Width - bmpX;
            bmpY:= spr.DrawingRect.bottom - pt.Y;
            bmpY:= spr.DrawingRect.Height - bmpY;
            Spr.MouseX := bmpX;
            Spr.MouseY := bmpY;

            if spr.Transparent then begin          // Transparent
              if lstEngines[i].PixelClick then begin
                if spr.fBMPCurrentFrame.Canvas.Pixels [BmpX,BmpY] <> spr.fBMPCurrentFrame.Canvas.Pixels [0,0] then begin
                  if changeCursor then cursor := crHandpoint;
                  if Assigned( FOnSpriteMouseMove ) and ( lstSpritesHandled )
                    then lstSpriteMoved.Add(spr);
                end;
              end
              else
              begin
                if changeCursor then cursor := crHandpoint;
                  if Assigned( FOnSpriteMouseMove ) and ( lstSpritesHandled )
                    then lstSpriteMoved.Add(spr);
              end;
            end
            else begin // no transparent
                if changeCursor then cursor := crHandpoint;
                  if Assigned( FOnSpriteMouseMove ) and ( lstSpritesHandled )
                    then lstSpriteMoved.Add(spr);
            end;
          end;
        end;

      end;
    end;


    if (lstSpriteMoved.Count > 0) and( Assigned( FOnSpriteMouseMove ) )  then begin
      if lstSpritesHandled then begin// se la precedente lista id sprites � stata gestita
        lstSpritesHandled := False;
        FOnSpriteMouseMove( self, lstSpriteMoved,Shift, lstSpritesHandled ); // lstSpritesHandled � globale. Quando � stata gestita, la posso rinnovare
      end;
    end;
NoSprites:
  //cells
  if Assigned( FOnCellMouseMove )  then begin
    pt := Point( XVisibleToVirtual(x), YVisibleToVirtual(y) );
    UnMap (pt.x,pt.y, tmpX, tmpY);
    FOnCellMouseMove( self, Shift, floor(tmpX), floor(tmpY ));
  end;

  // Theater MouseMove
  if Assigned(  FOnTheaterMouseMove )  then begin

    FOnTheaterMouseMove( self, X, Y, pt.X, pt.Y,Shift);
  end;

end;

procedure SE_Theater.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  tmpX, tmpY: Single;

  i, s, BmpX,BmpY: integer;
  spr: SE_Sprite;
  pt: TPoint;

begin

  if (Button = mbLeft) and (MousePan)  then  begin
    SetViewXY(MouseDownViewX - trunc((x - fMouseDownX)*fMouseScrollRate), MouseDownViewY - trunc((y - fMouseDownY)*fMouseScrollRate));
  end
  else Update;

  inherited MouseUp( Button, Shift, X, Y );

  pt := Point( XVisibleToVirtual(x), YVisibleToVirtual(y) );

  // Theater MouseUp
  if Assigned(  FOnTheaterMouseUp ) then begin
    FOnTheaterMouseUp( self, X, Y, pt.X, pt.Y,Button,Shift);
  end;
  // normal
  if Assigned( FOnMouseUp ) then   FOnMouseUp( self, Button, Shift, X, Y );

  lstSpriteClicked.Clear ;
    for i := lstEngines.Count - 1 downTo 0 Do begin
      if not lstEngines[i].ClickSprites then   Continue;
      if lstEngines[i].RenderBitmap = VisibleRender then begin
        pt.X:=X; // rimetto gli originali X Y
        pt.Y:=Y;
      end
      else
      begin    // ogni volta devo ribadire
        pt := Point( XVisibleToVirtual(x), YVisibleToVirtual(y) );
      end;
      for s := lstEngines[i].lstSprites.Count - 1 downto 0 do begin
        spr := lstEngines[i].Sprites[s];
        if spr.Visible then begin
          if spr.DrawingRect.Contains ( pt ) then begin
            bmpX:= spr.DrawingRect.Right  - pt.X    ; // <--- sul virtualBitmap
            bmpX:= spr.DrawingRect.Width - bmpX;
            bmpY:= spr.DrawingRect.bottom - pt.Y;
            bmpY:= spr.DrawingRect.Height - bmpY;
            Spr.MouseX := bmpX;
            Spr.MouseY := bmpY;
            if spr.Transparent then begin          // Transaprent
              if lstEngines[i].PixelClick then begin

                if spr.fBMPCurrentFrame.Canvas.Pixels [BmpX,BmpY] <> spr.fBMPCurrentFrame.Canvas.Pixels [0,0] then begin
                  if ( lstEngines[i].ClickSprites)
                    then lstSpriteClicked.Add(spr);

                end;
              end
              else begin
                  if  Assigned ( FOnSpriteMouseUp )and ( lstEngines[i].ClickSprites)
                    then lstSpriteClicked.Add(spr);
              end;
            end
            else begin // no transparent
                if  Assigned ( FOnSpriteMouseUp )and ( lstEngines[i].ClickSprites)
                  then lstSpriteClicked.Add(spr);
            end;
          end;
        end;
      end;
    end;


    if Assigned( FOnSpriteMouseUp ) and (lstSpriteClicked.Count > 0)
      then  FOnSpriteMouseUp( self, lstSpriteClicked , Button, Shift );
  //cells
   if Assigned( FOnCellMouseUp )  then begin
     pt := Point( XVisibleToVirtual(x), YVisibleToVirtual(y) );
     UnMap (pt.x,pt.y, tmpX, tmpY);
     FOnCellMouseUp( self, Button, Shift, floor(tmpX), floor(tmpY) );
   end;

end;




procedure SE_Theater.Assign(Source: TObject);
var
  si: SE_Theater;
begin
  if Source = nil then
    Clear
  else
  if Source is SE_Theater then
  begin         
    si := (Source as SE_Theater);
    fBackColor := si.fBackColor;
  end
  else
  if Source is TBitmap then
  begin
    fVisibleBitmap.CopyFromTBitmap(source as TBitmap);
    Update;
  end
  else
  if Source is SE_Bitmap then
  begin
    fVisibleBitmap.Assign(Source);
    Update;
  end;
end;


function SE_Theater.GetVisibleBitmap: SE_Bitmap;
begin
  result := fVisibleBitmap;
end;
function SE_Theater.GetVirtualBitmap: SE_Bitmap;
begin
  result := fVirtualBitmap;
end;


procedure SE_Theater.FinalPaint(ABitmap: SE_Bitmap; ABitmapScanline: ppointerarray );
var
  Rotated: SE_Bitmap;
begin
// Questo � il render su fVisibleBitmap calcolando lo zoom o lo scrolling
// Prima devo calcolare le dimensione e dove mettere nel canvas finale
  GetPaintCoords(VirtualSource1x, VirtualSource1y, VirtualSourceWidth, VirtualSourceHeight, fDstX, fDstY, fViewX, fViewY);

  if (csDesigning in ComponentState) or (fVisibleBitmap.Height = 0) or (fVisibleBitmap.Width = 0) then   exit;

  aBitmap.Canvas.Brush.Color := fbackColor;
  aBitmap.Canvas.Brush.Style := bsSolid;
  aBitmap.Canvas.FillRect(rect(0, 0, Width , Height ));

// Questo � il render finale
  {$ifdef angle}
  //Angle:= 45;
  if Angle <> 0 then begin
    Rotated := fVirtualBitmap.Rotate(Angle);
    Rotated.InternalRender(ABitmap, ABitmapScanline,
    fOffsetX, fOffsetY, fDstX, fDstY, VirtualSource1x, VirtualSource1y, VirtualSourceWidth, VirtualSourceHeight);
    freeandnil(Rotated);
    Exit;
  end;
  {$endif angle}

  fVirtualBitmap.InternalRender(ABitmap, ABitmapScanline,
  fOffsetX, fOffsetY, fDstX, fDstY, VirtualSource1x, VirtualSource1y, VirtualSourceWidth, VirtualSourceHeight);

end;




end.





