{.$DEFINE DEBUG}

{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: JvDataProviderImpl.pas, released on --.

The Initial Developer of the Original Code is Marcel Bestebroer
Portions created by Marcel Bestebroer are Copyright (C) 2002 - 2003 Marcel
Bestebroer
All Rights Reserved.

Contributor(s):
  Remko Bonte
  Peter Th�rnqvist

Last Modified: 2003-06-20

You may retrieve the latest version of this file at the Project JEDI's JVCL home page,
located at http://jvcl.sourceforge.net

Known Issues:
-----------------------------------------------------------------------------}

{$I JVCL.INC}

unit JvDataProviderImpl;

interface

uses
  Windows, Classes, SysUtils, Graphics, ImgList, Contnrs,
  JclBase,
  JvConsts, JvComponent, JvDataProvider;

type
  // Forwards
  TExtensibleInterfacedPersistent = class;
  TAggregatedPersistentEx = class;
  TJvBaseDataItem = class;
  TJvBaseDataItems = class;

  // Class references
  TAggregatedPersistentExClass = class of TAggregatedPersistentEx;
  TJvDataItemTextImplClass = class of TJvBaseDataItemTextImpl;
  TJvBaseDataItemClass = class of TJvBaseDataItem;
  TJvDataItemsClass = class of TJvBaseDataItems;

  // Generic classes (move to some other unit?)
  TExtensibleInterfacedPersistent = class(TPersistent, IUnknown)
  private
    FAdditionalIntfImpl: TList;
  protected
    FRefCount: Integer;
    { IUnknown }
    function _AddRef: Integer; virtual; stdcall;
    function _Release: Integer; virtual; stdcall;
    function QueryInterface(const IID: TGUID; out Obj): HResult; virtual; stdcall;
    procedure AddIntfImpl(const Obj: TAggregatedPersistentEx);
    procedure RemoveIntfImpl(const Obj: TAggregatedPersistentEx);
    function IndexOfImplClass(const AClass: TAggregatedPersistentExClass): Integer;
    procedure ClearIntfImpl;
    procedure InitImplementers; virtual;
    procedure SuspendRefCount;
    procedure ResumeRefCount;

    function IsStreamableExtension(AnExtension: TAggregatedPersistentEx): Boolean; virtual;
    procedure DefineProperties(Filer: TFiler); override;
    procedure ReadImplementers(Reader: TReader);
    procedure WriteImplementers(Writer: TWriter);
    procedure ReadImplementer(Reader: TReader);
    procedure WriteImplementer(Writer: TWriter; Instance: TAggregatedPersistentEx);
  public
    constructor Create;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function GetInterface(const IID: TGUID; out Obj): Boolean; virtual;
    class function NewInstance: TObject; override;
    property RefCount: Integer read FRefCount;
  end;

  TAggregatedPersistent = class(TPersistent)
  private
    FController: Pointer;
    function GetController: IUnknown;
  protected
    { IUnknown }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    constructor Create(Controller: IUnknown);
    property Controller: IUnknown read GetController;
  end;

  TAggregatedPersistentEx = class(TAggregatedPersistent)
  private
    FOwner: TExtensibleInterfacedPersistent;
  protected
    property Owner: TExtensibleInterfacedPersistent read FOwner;
  public
    constructor Create(AOwner: TExtensibleInterfacedPersistent); virtual;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function GetInterface(const IID: TGUID; out Obj): Boolean; virtual;
  end;

  TProviderNotifyEvent = procedure(ADataProvider: IJvDataProvider;
    AReason: TDataProviderChangeReason; Source: IUnknown) of object;

  // Generic event based provider notification
  TJvProviderNotification = class(TObject, IUnknown, IJvDataProviderNotify)
  private
    FOnChanging: TProviderNotifyEvent;
    FOnChanged: TProviderNotifyEvent;
  protected
    { IUnknown }
    function _AddRef: Integer; virtual; stdcall;
    function _Release: Integer; virtual; stdcall;
    function QueryInterface(const IID: TGUID; out Obj): HResult; virtual; stdcall;
    { IJvDataProviderNotify }
    procedure DataProviderChanging(const ADataProvider: IJvDataProvider;
      AReason: TDataProviderChangeReason; Source: IUnknown);
    procedure DataProviderChanged(const ADataProvider: IJvDataProvider;
      AReason: TDataProviderChangeReason; Source: IUnknown);
  public
    property OnChanging: TProviderNotifyEvent read FOnChanging write FOnChanging;
    property OnChanged: TProviderNotifyEvent read FOnChanged write FOnChanged;
  end;

  // Item implementation classes
  TJvDataItemAggregatedObject = class(TAggregatedPersistentEx)
  protected
    function Item: IJvDataItem;
    function ItemImpl: TJvBaseDataItem;
  end;

  TJvBaseDataItem = class(TExtensibleInterfacedPersistent, IJvDataItem)
  private
    FItems: Pointer;
    FItemsIntf: IJvDataItems;
    FID: string;
  protected
    { Initialize ID. Each item must have an unique identification. Implementers may choose how this
      ID is generated. No checks are made when items are added to a provider to ensure it's
      unique. If multiple items with the same ID are added only the first item in the tree will be
      selectable at design time. }
    procedure InitID; virtual;
    { Set the ID string. Used by InitID to set the actual ID string. }
    procedure SetID(Value: string);
    { Reference counting: add 1 if this item is part of a dynamic list (Items.IsDynamic returns
      True). Otherwise reference counting is not used. }
    function _AddRef: Integer; override; stdcall;
    { Reference counting: substract 1 if this item is part of a dynamic list (Items.IsDynamic returns
      True). Otherwise reference counting is not used. }
    function _Release: Integer; override; stdcall;

    { Streaming of an item. }
    procedure DefineProperties(Filer: TFiler); override;
    procedure ReadSubItems(Reader: TReader);
    procedure WriteSubItems(Writer: TWriter);
    { IJvDataItem methods and properties. }
    function GetItems: IJvDataItems;
    function GetImplementer: TObject;
    function GetID: string;
    property Items: IJvDataItems read GetItems;
    property Implementer: TObject read GetImplementer;
  public
    constructor Create(AOwner: IJvDataItems);
    procedure AfterConstruction; override;
  published
    property ID: string read GetID write SetID;
  end;

  TJvBaseDataItemTextImpl = class(TJvDataItemAggregatedObject, IJvDataItemText)
  protected
    function GetCaption: string; virtual; abstract;
    procedure SetCaption(const Value: string); virtual; abstract;
  public
    property Caption: string read GetCaption write SetCaption;
  end;

  TJvBaseDataItemImageImpl = class(TJvDataItemAggregatedObject, IJvDataItemImage)
  protected
    function GetAlignment: TAlignment; virtual; abstract;
    procedure SetAlignment(Value: TAlignment); virtual; abstract;
    function GetImageIndex: Integer; virtual; abstract;
    procedure SetImageIndex(Index: Integer); virtual; abstract;
    function GetSelectedIndex: Integer; virtual; abstract;
    procedure SetSelectedIndex(Value: Integer); virtual; abstract;
  end;

  TJvBaseDataItemRenderer = class(TJvDataItemAggregatedObject, IJvDataItemRenderer)
  protected
    procedure Draw(ACanvas: TCanvas; var ARect: TRect; State: TProviderDrawStates); virtual; abstract;
    function Measure(ACanvas: TCanvas): TSize; virtual; abstract;
  end;

  TJvBaseDataItemStates = class(TJvDataItemAggregatedObject, IJvDataItemStates)
  protected
    function Get_Enabled: TDataItemState; virtual; abstract;
    procedure Set_Enabled(Value: TDataItemState); virtual; abstract;
    function Get_Checked: TDataItemState; virtual; abstract;
    procedure Set_Checked(Value: TDataItemState); virtual; abstract;
    function Get_Visible: TDataItemState; virtual; abstract;
    procedure Set_Visible(Value: TDataItemState); virtual; abstract;
  end;

  // Items implementation classes
  TJvDataItemsAggregatedObject = class(TAggregatedPersistentEx)
  protected
    function Items: IJvDataItems;
    function ItemsImpl: TJvBaseDataItems;
  end;

  TJvBaseDataItems = class(TExtensibleInterfacedPersistent, IJvDataItems, IJvDataIDSearch)
    function IJvDataIDSearch.Find = FindByID;
  private
    FParent: Pointer;
    FParentIntf: IJvDataItem;
    FProvider: IJvDataProvider;
    FSubAggregate: TAggregatedPersistentEx;
  protected
    { Adds an item to the list. Called by the various add methods of the IJvDataItemsManagement and
      IJvDataItemsDesigner. }
    procedure InternalAdd(Item: IJvDataItem); virtual; abstract;
    { Determines if the item is streamable. }
    function IsStreamableItem(Item: IJvdataItem): Boolean; virtual;
    { Streaming methods }
    procedure DefineProperties(Filer: TFiler); override;
    procedure ReadItems(Reader: TReader);
    procedure WriteItems(Writer: TWriter);
    procedure ReadItem(Reader: TReader);
    procedure WriteItem(Writer: TWriter; Item: IJvDataItem);
    { IJvDataItems methods }
    function GetCount: Integer; virtual; abstract;
    function GetItem(I: Integer): IJvDataItem; virtual; abstract;
    function GetParent: IJvDataItem;
    function GetProvider: IJvDataProvider;
    function GetImplementer: TObject;
    function IsDynamic: Boolean; virtual;
    { IJvDataIDSearch methods }
    function FindByID(ID: string; const Recursive: Boolean = False): IJvDataItem;
  public
    constructor Create; virtual;
    constructor CreateProvider(const Provider: IJvDataProvider);
    constructor CreateParent(const Parent: IJvDataItem);
    procedure BeforeDestruction; override;
  end;

  TJvBaseDataItemsRenderer = class(TJvDataItemsAggregatedObject, IJvDataItemsRenderer)
  protected
    procedure DoDrawItem(ACanvas: TCanvas; var ARect: TRect; Item: IJvDataItem; State: TProviderDrawStates); virtual; abstract;
    function DoMeasureItem(ACanvas: TCanvas; Item: IJvDataItem): TSize; virtual; abstract;
    { IJvDataItemsRenderer methods }
    procedure DrawItemByIndex(ACanvas:TCanvas; var ARect: TRect; Index: Integer;
      State: TProviderDrawStates); virtual;
    function MeasureItemByIndex(ACanvas:TCanvas; Index: Integer): TSize; virtual;
    procedure DrawItem(ACanvas: TCanvas; var ARect: TRect; Item: IJvDataItem;
      State: TProviderDrawStates); virtual;
    function MeasureItem(ACanvas: TCanvas; Item: IJvDataItem): TSize; virtual;
    function AvgItemSize(ACanvas: TCanvas): TSize; virtual; abstract;
  end;

  TJvBaseDataItemsManagement = class(TJvDataItemsAggregatedObject, IJvDataItemsManagement)
  protected
    { IJvDataItemManagement methods }
    function Add(Item: IJvDataItem): IJvDataItem; virtual; abstract;
    function New: IJvDataItem; virtual; abstract;
    procedure Clear; virtual; abstract;
    procedure Delete(Index: Integer); virtual; abstract;
    procedure Remove(Item: IJvDataItem); virtual; abstract;
  end;

  TJvBaseDataItemsImagesImpl = class(TJvDataItemsAggregatedObject, IJvDataItemsImages)
  protected
    { IJvDataItemImages methods }
    function GetDisabledImages: TCustomImageList; virtual; abstract;
    procedure SetDisabledImages(const Value: TCustomImageList); virtual; abstract;
    function GetHotImages: TCustomImageList; virtual; abstract;
    procedure SetHotImages(const Value: TCustomImageList); virtual; abstract;
    function GetImages: TCustomImageList; virtual; abstract;
    procedure SetImages(const Value: TCustomImageList); virtual; abstract;
  end;

  // Standard item implementers
  TJvDataItemTextImpl = class(TJvBaseDataItemTextImpl)
  private
    FCaption: string;
  protected
    function GetCaption: string; override;
    procedure SetCaption(const Value: string); override;
  published
    property Caption: string read GetCaption write SetCaption;
  end;

  TJvDataItemImageImpl = class(TJvBaseDataItemImageImpl)
  private
    FAlignment: TAlignment;
    FImageIndex: Integer;
    FSelectedIndex: Integer;
  protected
    function GetAlignment: TAlignment; override;
    procedure SetAlignment(Value: TAlignment); override;
    function GetImageIndex: Integer; override;
    procedure SetImageIndex(Index: Integer); override;
    function GetSelectedIndex: Integer; override;
    procedure SetSelectedIndex(Value: Integer); override;
  published
    property Alignment: TAlignment read getAlignment write SetAlignment default taLeftJustify;
    property ImageIndex: Integer read GetImageIndex write SetImageIndex default 0;
    property SelectedIndex: Integer read GetSelectedIndex write SetSelectedIndex default 0;
  end;

  TJvBaseDataItemSubItems = class(TJvDataItemAggregatedObject, IJvDataItems)
  private
    FItems: IJvDataItems;
  protected
    property Items: IJvDataItems read FItems implements IJvDataItems;
  public
    constructor Create(AOwner: TExtensibleInterfacedPersistent; AItems: TJvBaseDataItems); reintroduce; virtual;
    destructor Destroy; override;
    procedure BeforeDestruction; override;
    function GetInterface(const IID: TGUID; out Obj): Boolean; override;
  end;

  TJvCustomDataItemTextRenderer = class(TJvBaseDataItemRenderer)
  protected
    procedure Draw(ACanvas: TCanvas; var ARect: TRect; State: TProviderDrawStates); override;
    function Measure(ACanvas: TCanvas): TSize; override;
  end;

  TJvCustomDataItemRenderer = class(TJvBaseDataItemRenderer)
  protected
    procedure Draw(ACanvas: TCanvas; var ARect: TRect; State: TProviderDrawStates); override;
    function Measure(ACanvas: TCanvas): TSize; override;
  end;

  TJvCustomDataItemStates = class(TJvBaseDataItemStates)
  private
    FEnabled: TDataItemState;
    FChecked: TDataItemState;
    FVisible: TDataItemState;
  protected
    procedure InitStatesUsage(UseEnabled, UseChecked, UseVisible: Boolean);
    function Get_Enabled: TDataItemState; override;
    procedure Set_Enabled(Value: TDataItemState); override;
    function Get_Checked: TDataItemState; override;
    procedure Set_Checked(Value: TDataItemState); override;
    function Get_Visible: TDataItemState; override;
    procedure Set_Visible(Value: TDataItemState); override;
  published
    property Enabled: TDataItemState read Get_Enabled write Set_Enabled;
    property Checked: TDataItemState read Get_Checked write Set_Checked;
    property Visible: TDataItemState read Get_Visible write Set_Visible;
  end;

  // Standard items implementers
  TJvCustomDataItemsTextRenderer = class(TJvBaseDataItemsRenderer)
  protected
    procedure DoDrawItem(ACanvas: TCanvas; var ARect: TRect; Item: IJvDataItem;
      State: TProviderDrawStates); override;
    function DoMeasureItem(ACanvas: TCanvas; Item: IJvDataItem): TSize; override;
    function AvgItemSize(ACanvas: TCanvas): TSize; override;
  end;

  TJvCustomDataItemsRenderer = class(TJvBaseDataItemsRenderer)
  protected
    procedure DoDrawItem(ACanvas: TCanvas; var ARect: TRect; Item: IJvDataItem;
      State: TProviderDrawStates); override;
    function DoMeasureItem(ACanvas: TCanvas; Item: IJvDataItem): TSize; override;
    function AvgItemSize(ACanvas: TCanvas): TSize; override;
  end;

  TJvDataItemsList = class(TJvBaseDataItems)
  private
    FList: TObjectList;
  protected
    procedure InternalAdd(Item: IJvDataItem); override;
    function IsDynamic: Boolean; override;
    function GetCount: Integer; override;
    function GetItem(I: Integer): IJvDataItem; override;
  public
    { TODO: Rewrite as constructor/destructor }
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    property List: TObjectList read FList;
  end;

  TJvBaseDataItemsListManagement = class(TJvBaseDataItemsManagement)
  protected
    function Add(Item: IJvDataItem): IJvDataItem; override;
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    procedure Remove(Item: IJvDataItem); override;
  end;

  TJvCustomDataItemsImages = class(TJvBaseDataItemsImagesImpl)
  private
    FDisabledImages: TCustomImageList;
    FHotImages: TCustomImageList;
    FImages: TCustomImageList;
  protected
    function GetDisabledImages: TCustomImageList; override;
    procedure SetDisabledImages(const Value: TCustomImageList); override;
    function GetHotImages: TCustomImageList; override;
    procedure SetHotImages(const Value: TCustomImageList); override;
    function GetImages: TCustomImageList; override;
    procedure SetImages(const Value: TCustomImageList); override;
  published
    property DisabledImages: TCustomImageList read GetDisabledImages write SetDisabledImages;
    property HotImages: TCustomImageList read GetHotImages write SetHotImages;
    property Images: TCustomImageList read GetImages write SetImages;
  end;

  // Generic data provider implementation
  TJvDataProviderTree = type Integer;
  TJvDataProviderItemID = type string;
  TJvCustomDataProvider = class(TJvComponent, {$IFNDEF COMPILER6_UP}IInterfaceComponentReference, {$ENDIF}
    IJvDataProvider, IJvDataItems)
  private
    FDataItemsImpl: TJvBaseDataItems;
    FNotifiers: TInterfaceList;
    FTreeItems: TJvDataProviderTree;
    FConsumerStack: TInterfaceList;
    FContextStack: TInterfaceList;
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; override;
    procedure Changing(ChangeReason: TDataProviderChangeReason; Source: IUnknown = nil);
    procedure Changed(ChangeReason: TDataProviderChangeReason; Source: IUnknown = nil);
    class function PersistentDataItems: Boolean; dynamic;
    class function ItemsClass: TJvDataItemsClass; dynamic;
    procedure DefineProperties(Filer: TFiler); override;
    procedure ReadRoot(Reader: TReader);
    procedure WriteRoot(Writer: TWriter);
    procedure AddToArray(var ClassArray: TClassArray; AClass: TClass);
    procedure DeleteFromArray(var ClassArray: TClassArray; Index: Integer);
    function IndexOfClass(AClassArray: TClassArray; AClass: TClass): Integer;
    procedure RemoveFromArray(var ClassArray: TClassArray; AClass: TClass);
    function IsTreeProvider: Boolean; dynamic;
    {$IFNDEF COMPILER6_UP}
    { IInterfaceComponentReference }
    function GetComponent: TComponent;
    {$ENDIF COMPILER6_UP}
    { IDataProvider }
    function GetItems: IJvDataItems; 
    procedure RegisterChangeNotify(ANotify: IJvDataProviderNotify); dynamic;
    procedure UnregisterChangeNotify(ANotify: IJvDataProviderNotify); dynamic;
    function ConsumerClasses: TClassArray; dynamic;
    procedure SelectConsumer(Consumer: IJvDataConsumer);
    function SelectedConsumer: IJvDataConsumer;
    procedure ReleaseConsumer;
    procedure SelectContext(Context: IJvDataContext);
    function SelectedContext: IJvDataContext;
    procedure ReleaseContext;

    property DataItemsImpl: TJvBaseDataItems read FDataItemsImpl implements IJvDataItems;
    property Items: TJvDataProviderTree read FTreeItems write FTreeItems stored False;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeforeDestruction; override;
    function GetInterface(const IID: TGUID; out Obj): Boolean; virtual;
  end;

// Helper routines
{ Locate nearest IJvDataItems* implementation for a specific item. }
function DP_FindItemsIntf(AItem: IJvDataItem; IID: TGUID; out Obj): Boolean;
{ Locate nearest IJvDataItemsRenderer implementation for a specific item. }
function DP_FindItemsRenderer(AItem: IJvDataItem; out Renderer: IJvDataItemsRenderer): Boolean;
{ Locate nearest IJvDataItemsImages implementation for a specific item. }
function DP_FindItemsImages(AItem: IJvDataItem; out Images: IJvDataItemsImages): Boolean;
{ Generate items list to emulate trees in a flat list control }
procedure DP_GenItemsList(RootList: IJvDataItems; ItemList: TStrings);
{ Convert TOwnerDrawState to TProviderDrawStates }
function DP_OwnerDrawStateToProviderDrawState(State: TOwnerDrawState): TProviderDrawStates;
{ Atomically select a consumer/context pair, pushing the current consumer/context onto their
  internal stacks. }
procedure DP_SelectConsumerContext(Provider: IJvDataProvider; Consumer: IJvDataConsumer; Context: IJvDataContext);
{ Atomically release a consumer/context pair, reinstating the prior pair on the respective stacks. }
procedure DP_ReleaseConsumerContext(Provider: IJvDataProvider);

// Helper classes: rendering helpers
type
  { Render class to be used by both the IJvDataItemsRenderer as well as IJvDataItemRenderer
    implementers. Reduces code duplication if both type of implementers can use the same rendering
    mechanism. }
  TJvDP_ProviderBaseRender = class(TObject)
  private
    FItem: IJvDataItem;
    FCanvas: TCanvas;
    FState: TProviderDrawStates;
  protected
    Rect: TRect;
    procedure Prepare(ForMeasure: Boolean); virtual; abstract; 
    procedure DoDraw; virtual; abstract;
    function DoMeasure: TSize; virtual; abstract;

    property Item: IJvDataItem read FItem;
    property Canvas: TCanvas read FCanvas;
    property State: TProviderDrawStates read FState;
  public
    constructor Create(AItem: IJvDataItem; ACanvas: TCanvas; AState: TProviderDrawStates);
    class procedure Draw(AItem: IJvDataItem; ACanvas: TCanvas; var ARect: TRect; AState: TProviderDrawStates);
    class function Measure(AItem: IJvDataItem; ACanvas: TCanvas; AState: TProviderDrawStates): TSize;
  end;

  TJvDP_ProviderTextOnlyRender = class(TJvDP_ProviderBaseRender)
  private
    FHasNoText: Boolean;
    FText: string;
    FTextRect: TRect;
  protected
    procedure Prepare(ForMeasure: Boolean); override;
    procedure DoDraw; override;
    function DoMeasure: TSize; override;

    property HasNoText: Boolean read FHasNoText write FHasNoText;
    property Text: string read FText write FText;
    property TextRect: TRect read FTextRect write FTextRect;
  end;

  TJvDP_ProviderImgAndTextRender = class(TJvDP_ProviderTextOnlyRender)
  private
    FHasImage: Boolean;
    FHasDisabledImage: Boolean;
    FImages: TCustomImageList;
    FImageIndex: Integer;
    FAlignment: TAlignment;
  protected
    procedure Prepare(ForMeasure: Boolean); override;
    procedure DoDraw; override;
    function DoMeasure: TSize; override;

    property HasImage: Boolean read FHasImage write FHasImage;
    property HasDisabledImage: Boolean read FHasDisabledImage write FHasDisabledImage;
    property Images: TCustomImageList read FImages write FImages;
    property ImageIndex: Integer read FImageIndex write FImageIndex;
    property Alignment: TAlignment read FAlignment write FAlignment;
  end;

  TJvDataConsumerAggregatedObject = class;
  TJvDataConsumerAggregatedObjectClass = class of TJvDataConsumerAggregatedObject;
  TJvDataConsumer = class(TExtensibleInterfacedPersistent, IJvDataConsumer, IJvDataProviderNotify)
  private
    FOwner: TComponent;
    FAttrList: array of Integer;
    FProvider: IJvDataProvider;
    FContext: IJvDataContext;
    FOnChanged: TNotifyEvent;
    FNeedFixups: Boolean;
    FFixupContext: TJvDataContextID;
    procedure SetProvider(Value: IJvDataProvider);
    {$IFNDEF COMPILER6_UP}
    function GetProviderComp: TComponent;
    procedure SetProviderComp(Value: TComponent);
    {$ENDIF COMPILER6_UP}
  protected
    function _AddRef: Integer; override; stdcall;
    function _Release: Integer; override; stdcall;
    { Event triggering }
    procedure DoProviderChanging(ADataProvider: IJvDataProvider; AReason: TDataProviderChangeReason; Source: IUnknown);
    procedure DoProviderChanged(ADataProvider: IJvDataProvider; AReason: TDataProviderChangeReason; Source: IUnknown);
    procedure DoChanged;
    { Misc. }
    procedure DoAddAttribute(Attr: Integer);
    procedure Changed;
    procedure ProviderChanging;
    procedure ProviderChanged;
    procedure ContextChanging;
    procedure ContextChanged;
    procedure UpdateExtensions; virtual;
    procedure FixupExtensions;
    procedure ViewChanged(AExtension: TJvDataConsumerAggregatedObject);
    function ExtensionCount: Integer;
    function Extension(Index: Integer): TJvDataConsumerAggregatedObject;
    { Property access }
    function GetContext: TJvDataContextID;
    procedure SetContext(Value: TJvDataContextID);
    { IJvDataProviderNotify methods }
    procedure DataProviderChanging(const ADataProvider: IJvDataProvider; AReason: TDataProviderChangeReason; Source: IUnknown);
    procedure DataProviderChanged(const ADataProvider: IJvDataProvider; AReason: TDataProviderChangeReason; Source: IUnknown);
    { IJvDataConsumer methods }
    function VCLComponent: TComponent;
    function AttributeApplies(Attr: Integer): Boolean;
  public
    constructor Create(AOwner: TComponent; Attributes: array of Integer);
    destructor Destroy; override;
    { Direct link to actual provider interface. This is done to aid in the implementation (less
      IFDEF's in the code; always refer to ProviderIntf and it's working in all Delphi versions). }
    function ProviderIntf: IJvDataProvider;
    procedure SetProviderIntf(Value: IJvDataProvider);
    function ContextIntf: IJvDataContext;
    procedure SetContextIntf(Value: IJvDataContext);
    procedure Enter;
    procedure Leave;

    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  published
    {$IFDEF COMPILER6_UP}
    property Provider: IJvDataProvider read FProvider write setProvider;
    {$ELSE}
    property Provider: TComponent read GetProviderComp write SetProviderComp;
    {$ENDIF COMPILER6_UP}
    property Context: TJvDataContextID read GetContext write SetContext;
  end;

  TJvDataConsumerAggregatedObject = class(TAggregatedPersistentEx)
  protected
    { Called when the Provider/Context are set and NotifyFixups has been called earlier. It doesn't
      matter which sub service called NotifyFixups, all services are notified if the
      provider/context are set. }
    procedure Fixup; virtual;
    { Called after a new provider is selected to determine if the sub service can stay around.
      Return False to have the sub service removed (the default implementation) or set to True to
      keep it around. Note that on entry to this method the new provider is already selected. }
    function KeepOnProviderChange: Boolean; virtual;
    { Called after a new context is selected to determine if the sub service can stay around.
      Return False to have the sub service removed or set to True to keep it around (default
      implementation). Note that on entry to this method the new context is already selected. }
    function KeepOnContextChange: Boolean; virtual;
    { Notifies the consumer service a change has taken place. Sub services should call this method
      when something has changed. }
    procedure Changed;
    { Notifies the consumer service (and other extensions) a change has taken place that might have
      influenced the view list. }
    procedure NotifyViewChanged;
    { Called after the view has changed by another extension. }
    procedure ViewChanged(AExtension: TJvDataConsumerAggregatedObject); virtual;
    { Signal to the consumer service that settings need to be applies but the provider/context was
      not yet available. This may occur during streaming in from the DFM. As soon as the provider is
      known, the context is also set and Fixup is called for all sub services. }
    procedure NotifyFixups;
    { Called when the provider is about to be changed. }
    procedure ProviderChanging; virtual;
    { Called when the provider has changed but only after KeepOnProviderChange returned True. }
    procedure ProviderChanged; virtual;
    { Called when the context is about to be changed. }
    procedure ContextChanging; virtual;
    { Called when the context has changed but only after KeepOnContextChange returned True. }
    procedure ContextChanged; virtual;
    { Reference to the consumer service interface. }
    function Consumer: IJvDataConsumer;
    { Reference to the consumer service implementation. }
    function ConsumerImpl: TJvDataConsumer;
    { Retrieve the root IJvDataItems reference. }
    function RootItems: IJvDataItems;
  end;

  { Consumer sub service to select the context to use for the consumer. Only needed for design time
    purposes; use TJvDataConsumer.Context to change it directly. }
  TJvDataConsumerContext = class(TJvDataConsumerAggregatedObject)
  protected
    function GetContext: IJvDataContext;
    procedure SetContext(Value: IJvDataContext);
  published
    property Context: IJvDataContext read GetContext write SetContext;
  end;

  { Consumer sub service to select the item to display or item that serves as the root. }
  TJvDataConsumerItemSelect = class(TJvDataConsumerAggregatedObject, IJvDataConsumerItemSelect)
    { Method resolutions }
    function IJvDataConsumerItemSelect.GetItem = GetItemIntf;
    procedure IJvDataConsumerItemSelect.SetItem = SetItemIntf;
  private
    FItemID: TJvDataItemID;
    FItem: IJvDataItem;
  protected
    procedure Fixup; override;
    function GetItem: TJvDataItemID;
    procedure SetItem(Value: TJvDataItemID);
  public
    function GetItemIntf: IJvDataItem;
    procedure SetItemIntf(Value: IJvDataItem);
  published
    property Item: TJvDataItemID read GetItem write SetItem;
  end;

  { Consumer sub service to maintain a flat list of the data tree. }
  TJvCustomDataConsumerViewList = class(TJvDataConsumerAggregatedObject, IJvDataConsumerViewList)
  private
    FAutoExpandLevel: Integer;
    FExpandOnNewItem: Boolean;
    FNotifier: TJvProviderNotification;
  protected
    function KeepOnProviderChange: Boolean; override;
    procedure ProviderChanging; override;
    procedure ProviderChanged; override;
    procedure ContextChanged; override;
    procedure ViewChanged(AExtension: TJvDataConsumerAggregatedObject); override;
    procedure DataProviderChanging(ADataProvider: IJvDataProvider;
      AReason: TDataProviderChangeReason; Source: IUnknown);
    procedure DataProviderChanged(ADataProvider: IJvDataProvider;
      AReason: TDataProviderChangeReason; Source: IUnknown);
    function InternalItemSibling(ParentIndex: Integer; var ScanIndex: Integer): Integer;
    function Get_AutoExpandLevel: Integer;
    procedure Set_AutoExpandLevel(Value: Integer);
    function Get_ExpandOnNewItem: Boolean;
    procedure Set_ExpandOnNewItem(Value: Boolean);
    { Add an item as the sub item of the item specified. The parent item will be marked as being
      expanded. }
    procedure AddItem(Index: Integer; Item: IJvDataItem; ExpandToLevel: Integer = 0); virtual; abstract;
    { Add a list of items at the specified Index. The item preceding that index will be handled as
      if it was the parent of all items to be inserted. This will also mark that item as being
      expanded. }
    procedure AddItems(var Index: Integer; Items: IJvDataItems; ExpandToLevel: Integer = 0); virtual; abstract;
    procedure AddChildItem(ParentIndex: Integer; Item: IJvDataItem); virtual; abstract;
    procedure InsertItem(InsertIndex, ParentIndex: Integer; Item: IJvDataItem); virtual; abstract;
    { Delete the specified item and the items sub tree. }
    procedure DeleteItem(Index: Integer); virtual; abstract;
    { Deletes the specified items sub tree and mark the item as not-expanded }
    procedure DeleteItems(Index: Integer); virtual; abstract;
    procedure ClearView; virtual;
    procedure RebuildView; virtual;

    property AutoExpandLevel: Integer read FAutoExpandLevel write FAutoExpandLevel;
    property ExpandOnNewItem: Boolean read FExpandOnNewItem write FExpandOnNewItem;
  public
    constructor Create(AOwner: TExtensibleInterfacedPersistent); override;
    destructor Destroy; override;
    procedure ExpandTreeTo(Item: IJvDataItem); virtual;
    { Toggles an item's expanded state. If an item becomes expanded, the item's sub item as present
      in the IJvDataItems instance will be added; if an item becomes collapsed the sub items are
      removed from the view. }
    procedure ToggleItem(Index: Integer); virtual; abstract;
    { Locate an item in the view list, returning it's absolute index. }
    function IndexOfItem(Item: IJvDataItem): Integer; virtual; abstract;
    { Locate an item ID in the view list, returning it's absolute index. }
    function IndexOfID(ID: TJvDataItemID): Integer; virtual; abstract;
    { Locate an item in the view list, returning it's index in the parent item. }
    function ChildIndexOfItem(Item: IJvDataItem): Integer; virtual; abstract;
    { Locate an item ID in the view list, returning it's index in the parent item. }
    function ChildIndexOfID(ID: TJvDataItemID): Integer; virtual; abstract;
    { Retrieve the IJvDataItem reference given the absolute index into the view list. }
    function Item(Index: Integer): IJvDataItem; virtual; abstract;
    { Retrieve an items level given the absolute index into the view list. }
    function ItemLevel(Index: Integer): Integer; virtual; abstract;
    { Retrieve an items expanded state given the absolute index into the view list. }
    function ItemIsExpanded(Index: Integer): Boolean; virtual; abstract;
    { Determine if an item has children given the absolute index into the view list. }
    function ItemHasChildren(Index: Integer): Boolean; virtual; abstract;
    { Retrieve an items parent given the absolute index into the view list. }
    function ItemParent(Index: Integer): IJvDataItem; virtual; abstract;
    { Retrieve an items parent absolute index given the absolute index into the view list. }
    function ItemParentIndex(Index: Integer): Integer; virtual; abstract;
    { Retrieve an items sibling given an absolute index. }
    function ItemSibling(Index: Integer): IJvDataItem; virtual; abstract;
    { Retrieve the index of an items sibling given an absolute index. }
    function ItemSiblingIndex(Index: Integer): Integer; virtual; abstract;
    { Retrieve the IJvDataItem reference given the child index and a parent item. }
    function SubItem(Parent: IJvDataItem; Index: Integer): IJvDataItem; overload; virtual; abstract;
    { Retrieve the IJvDataItem reference given the child index and a parent absolute index. }
    function SubItem(Parent, Index: Integer): IJvDataItem; overload; virtual; abstract;
    { Retrieve the absolute index given a child index and a parent item. }
    function SubItemIndex(Parent: IJvDataItem; Index: Integer): Integer; overload; virtual; abstract;
    { Retrieve the absolute index given a child index and a parent absolute index. }
    function SubItemIndex(Parent, Index: Integer): Integer; overload; virtual; abstract;
    { Retrieve info on grouping; each bit represents a level, if the bit is set the item at that
      level has another sibling. Can be used to render tree lines. Note that this is very generic
      implementation that is not the fastest. To make this info readily available will require
      a descendant that stores and updates this info on a per item basis. This method can then be
      adpated to use that info directly. }
    function ItemGroupInfo(Index: Integer): TDynIntegerArray; virtual;
    { Retrieve the number of viewable items. }
    function Count: Integer; virtual; abstract;
  end;

  { View list; uses the least possible amount of memory but may be slow to find sibling/child
    items. }
  TViewListItem = record
    ItemID: string;
    Flags: Integer; // lower 24 bits contain item level
  end;
  TViewListItems = array of TViewListItem;

  TJvDataConsumerViewList = class(TJvCustomDataConsumerViewList)
  private
    FViewItems: TViewListItems;
  protected
    procedure AddItem(Index: Integer; Item: IJvDataItem; ExpandToLevel: Integer = 0); override;
    procedure AddChildItem(ParentIndex: Integer; Item: IJvDataItem); override;
    procedure AddItems(var Index: Integer; Items: IJvDataItems; ExpandToLevel: Integer = 0); override;
    procedure InsertItem(InsertIndex, ParentIndex: Integer; Item: IJvDataItem); override;
    procedure DeleteItem(Index: Integer); override;
    procedure DeleteItems(Index: Integer); override;
  public
    procedure ToggleItem(Index: Integer); override;
    function IndexOfItem(Item: IJvDataItem): Integer; override;
    function IndexOfID(ID: TJvDataItemID): Integer; override;
    function ChildIndexOfItem(Item: IJvDataItem): Integer; override;
    function ChildIndexOfID(ID: TJvDataItemID): Integer; override;
    function Item(Index: Integer): IJvDataItem; override;
    function ItemLevel(Index: Integer): Integer; override;
    function ItemIsExpanded(Index: Integer): Boolean; override;
    function ItemHasChildren(Index: Integer): Boolean; override;
    function ItemParent(Index: Integer): IJvDataItem; override;
    function ItemParentIndex(Index: Integer): Integer; override;
    function ItemSibling(Index: Integer): IJvDataItem; override;
    function ItemSiblingIndex(Index: Integer): Integer; override;
    function SubItem(Parent: IJvDataItem; Index: Integer): IJvDataItem; override;
    function SubItem(Parent, Index: Integer): IJvDataItem; override;
    function SubItemIndex(Parent: IJvDataItem; Index: Integer): Integer; override;
    function SubItemIndex(Parent, Index: Integer): Integer; override;
    function Count: Integer; override;
  end;

// Rename and move to JvFunctions? Converts a buffer into a string of hex digits.
function HexBytes(const Buf; Length: Integer): string;
// Move to other unit? Render text in a disabled way (much like TLabel does)
procedure DisabledTextRect(ACanvas: TCanvas; var ARect: TRect; Left, Top: Integer; Text: string);

implementation

uses
  ActiveX, Consts, {$IFDEF COMPILER6_UP}RTLConsts, {$ENDIF}Controls, TypInfo,
  {$IFDEF DEBUG}
  Dialogs, 
  DBugIntf,
  {$ENDIF}
  JvTypes;

const
  vifHasChildren = Integer($80000000);
  vifCanHaveChildren = Integer($40000000);
  vifExpanded = Integer($20000000);

function HexBytes(const Buf; Length: Integer): string;
var
  P: PChar;
begin
  Result := '';
  P := @Buf;
  while Length > 1 do
  begin
    Result := Result + IntToHex(Ord(P^), 2);
    Inc(P);
    Dec(Length);
  end;
end;

//TODO: Copied from JvxCtrls.pas to avoid dependancy. Must move to another unit.

type
  TShadowPosition = (spLeftTop, spLeftBottom, spRightBottom, spRightTop);

function DrawShadowText(DC: HDC; Str: PChar; Count: Integer; var Rect: TRect;
  Format: Word; ShadowSize: Byte; ShadowColor: TColorRef;
  ShadowPos: TShadowPosition): Integer;
var
  RText, RShadow: TRect;
  Color: TColorRef;
  OldBkMode: Integer;
begin
  RText := Rect;
  RShadow := Rect;
  Color := SetTextColor(DC, ShadowColor);
  case ShadowPos of
    spLeftTop:
      OffsetRect(RShadow, -ShadowSize, -ShadowSize);
    spRightBottom:
      OffsetRect(RShadow, ShadowSize, ShadowSize);
    spLeftBottom:
      begin
        {OffsetRect(RText, ShadowSize, 0);}
        OffsetRect(RShadow, -ShadowSize, ShadowSize);
      end;
    spRightTop:
      begin
        {OffsetRect(RText, 0, ShadowSize);}
        OffsetRect(RShadow, ShadowSize, -ShadowSize);
      end;
  end;
  Result := DrawText(DC, Str, Count, RShadow, Format);
  if Result > 0 then
    Inc(Result, ShadowSize);
  SetTextColor(DC, Color);
  OldBkMode := SetBkMode(DC, TRANSPARENT);
  try
    DrawText(DC, Str, Count, RText, Format);
  finally
    SetBkMode(DC, OldBkMode);
  end;
  UnionRect(Rect, RText, RShadow);
end;

procedure DisabledTextRect(ACanvas: TCanvas; var ARect: TRect; Left, Top: Integer; Text: string);
begin
  ACanvas.Font.Color := clGrayText;
  DrawShadowText(ACanvas.Handle, PChar(Text), Length(Text), ARect, 0, 1, ColorToRGB(clBtnHighlight),
    spRightBottom);
end;

procedure AddItemsToList(AItems: IJvDataItems; ItemList: TStrings; Level: Integer);
var
  I: Integer;
  ThisItem: IJvDataItem;
  SubItems: IJvDataItems;
begin
  for I := 0 to AItems.Count - 1 do
  begin
    ThisItem := AItems.Items[I];
    ItemList.AddObject(ThisItem.GetID, TObject(Level));
    if Supports(ThisItem, IJvDataItems, SubItems) then
      AddItemsToList(SubItems, ItemList, Level + 1);
  end;
end;

function DP_FindItemsIntf(AItem: IJvDataItem; IID: TGUID; out Obj): Boolean;
begin
  while (AItem <> nil) and not Supports(AItem.Items, IID, Obj) do
    AItem := AItem.Items.Parent;
  Result := AItem <> nil;
end;

function DP_FindItemsRenderer(AItem: IJvDataItem; out Renderer: IJvDataItemsRenderer): Boolean;
begin
  Result := DP_FindItemsIntf(AItem, IJvDataItemsRenderer, Renderer);
end;

function DP_FindItemsImages(AItem: IJvDataItem; out Images: IJvDataItemsImages): Boolean;
begin
  Result := DP_FindItemsIntf(AItem, IJvDataItemsImages, Images);
end;

procedure DP_GenItemsList(RootList: IJvDataItems; ItemList: TStrings);
begin
  ItemList.Clear;
  AddItemsToList(RootList, ItemList, 0);
end;

function DP_OwnerDrawStateToProviderDrawState(State: TOwnerDrawState): TProviderDrawStates;
begin
  Move(State, Result, SizeOf(State));
end;

procedure DP_SelectConsumerContext(Provider: IJvDataProvider; Consumer: IJvDataConsumer; Context: IJvDataContext);
begin
  Provider.SelectConsumer(Consumer);
  try
    Provider.SelectContext(Context);
  except
    Provider.ReleaseConsumer;
    raise;
  end;
end;

procedure DP_ReleaseConsumerContext(Provider: IJvDataProvider);
var
  CurConsumer: IJvDataConsumer;
begin
  CurConsumer := Provider.SelectedConsumer;
  Provider.ReleaseConsumer;
  try
    Provider.ReleaseContext;
  except
    Provider.SelectConsumer(CurConsumer);
    raise;
  end;
end;

{ TJvDP_ProviderBaseRender }

constructor TJvDP_ProviderBaseRender.Create(AItem: IJvDataItem; ACanvas: TCanvas; AState: TProviderDrawStates);
begin
  inherited Create;
  FItem := AItem;
  FCanvas := ACanvas;
  FState := AState;
end;

class procedure TJvDP_ProviderBaseRender.Draw(AItem: IJvDataItem; ACanvas: TCanvas; var ARect: TRect; AState: TProviderDrawStates);
begin
  with Self.Create(AItem, ACanvas, AState) do
  try
    Rect := ARect;
    Prepare(False);
    DoDraw;
  finally
    Free;
  end;
end;

class function TJvDP_ProviderBaseRender.Measure(AItem: IJvDataItem; ACanvas: TCanvas; AState: TProviderDrawStates): TSize;
begin
  with Self.Create(AItem, ACanvas, AState) do
  try
    Prepare(True);
    Result := DoMeasure;
  finally
    Free;
  end;
end;

{ TJvDP_ProviderTextOnlyRender }

procedure TJvDP_ProviderTextOnlyRender.Prepare(ForMeasure: Boolean);
var
  TextIntf: IJvDataItemText;
begin
  HasNoText := not Supports(Item, IJvDataItemText, TextIntf);
  if HasNoText then
    FText := SDataItemRenderHasNoText
  else
    FText := TextIntf.Caption;
end;

procedure TJvDP_ProviderTextOnlyRender.DoDraw;
begin
  Canvas.TextRect(Rect, Rect.Left, Rect.Top, FText);
end;

function TJvDP_ProviderTextOnlyRender.DoMeasure: TSize;
begin
  Result := Canvas.TextExtent(FText);
end;

{ TJvDP_ProviderImgAndTextRender }

procedure TJvDP_ProviderImgAndTextRender.Prepare(ForMeasure: Boolean);
var
  ImgIntf: IJvDataItemImage;
  ImgsIntf: IJvDataItemsImages;
begin
  inherited Prepare(ForMeasure);
  FImageIndex := -1;
  FImages := nil;
  if Supports(Item, IJvDataItemImage, ImgIntf) then
  begin
    FAlignment := ImgIntf.Alignment;
    if DP_FindItemsImages(Item, ImgsIntf) then
    begin
      { We have an item that supports an image and one of it's parents has an imagelist assigned. }
      if (pdsDisabled in State) and (ImgsIntf.DisabledImages <> nil) then
      begin
        FImages := ImgsIntf.DisabledImages;
        FHasDisabledImage := True;
      end
      else
      begin
        FHasDisabledImage := False;
        if (pdsHot in State) and (ImgsIntf.HotImages <> nil) then
          FImages := ImgsIntf.HotImages
        else
          FImages := ImgsIntf.Images;
      end;
      if (pdsSelected in State) and (ImgIntf.SelectedIndex <> -1) then
        FImageIndex := ImgIntf.SelectedIndex
      else
      begin
        FImageIndex := ImgIntf.ImageIndex;
        if FImageIndex < 0 then
          FImageIndex := ImgIntf.SelectedIndex;
      end;
    end;
  end;
  FHasImage := (FImages <> nil) and (FImageIndex > -1);
  if HasImage and HasNoText then
    Text := '';
end;

procedure TJvDP_ProviderImgAndTextRender.DoDraw;
var
  rgn: HRGN;
  iSaveDC: Integer;
  TxtW: Integer;
begin
  rgn := CreateRectRgn(0,0,0,0);
  GetClipRgn(Canvas.handle, rgn);
  try
    IntersectClipRect(Canvas.Handle, Rect.Left, Rect.Top, Rect.Right, Rect.Bottom);
    if HasImage then
    begin
      iSaveDC := SaveDC(Canvas.Handle);
      try
        // Apply alignment rules and render the image
        case Alignment of
          taLeftJustify:
            begin
              Images.Draw(Canvas, Rect.Left, Rect.Top, ImageIndex, HasDisabledImage or not (pdsDisabled in State));
              Rect.Left := Rect.Left + Images.Width + 2;
            end;
          taRightJustify:
            begin
              Images.Draw(Canvas, Rect.Right - Images.Width, Rect.Top, ImageIndex, HasDisabledImage or not (pdsDisabled in State));
              Rect.Right := Rect.Right - Images.Width - 2;
            end;
          taCenter:
            begin
              Images.Draw(Canvas, Rect.Left + ((Rect.Right - Rect.Left - Images.Width) div 2),
                Rect.Top, ImageIndex, HasDisabledImage or not (pdsDisabled in State));
              Rect.Top := Rect.Top + Images.Height + 2;
              TxtW := Canvas.TextWidth(Text);
              Rect.Left := Rect.Left + ((Rect.Right - Rect.Left - TxtW) div 2);
            end;
        end;
      finally
        if iSaveDC <> 0 then
          RestoreDC(Canvas.Handle, iSaveDC);
      end;
    end;
    if pdsGrayed in State then
      Canvas.Font.Color := clGrayText;
    if (pdsDisabled in State) and not (pdsGrayed in State) then
      DisabledTextRect(Canvas, Rect, Rect.Left, Rect.Top, Text)
    else
      Canvas.TextRect(Rect, Rect.Left, Rect.Top, Text);
  finally
    SelectClipRgn(Canvas.Handle, rgn);
    DeleteObject(rgn);
  end;
end;

function TJvDP_ProviderImgAndTextRender.DoMeasure: TSize;
begin
  if HasImage then
  begin
    // Apply alignment rules and render the image
    case Alignment of
      taLeftJustify,
      taRightJustify:
        begin
          Result := Canvas.TextExtent(Text);
          Inc(Result.cx, Images.Width + 2);
          if Images.Height > Result.cy then
            Result.cy := Images.Height;
        end;
      taCenter:
        begin
          Result := Canvas.TextExtent(Text);
          Inc(Result.cy, Images.Height + 2);
          if Images.Width > Result.cx then
            Result.cx := Images.Width;
        end;
    end;
  end
  else
    Result := inherited DoMeasure;
end;

type
  TOpenReader = class(TReader);
//  TOpenWriter = class(TWriter);
 {$M+}
  TOpenWriter = class(TWriter)
    function GetPropPath: string;
    function PropPathField: PString;
    procedure SetPropPath(const NewPath: string);
    property PropPath: string read GetPropPath write SetPropPath;
  published
    property RootAncestor;
  end;
  {$M-}

  function TOpenWriter.GetPropPath: string;
  begin
    Result := PropPathField^;
  end;

  function TOpenWriter.PropPathField: PString;
  var
    RAPI: PPropInfo;
  begin
    RAPI := GetPropInfo(TOpenWriter, 'RootAncestor');
    if RAPI = nil then
      raise Exception.Create('Internal error.');
    Result := Pointer(Cardinal(RAPI.GetProc) and $00FFFFFF + Cardinal(Self) + 4);
  end;

  procedure TOpenWriter.SetPropPath(const NewPath: string);
  begin
    if NewPath <> PropPath then
      PropPathField^ := NewPath;
  end;

{ TJvDataItemAggregatedObject }

function TJvDataItemAggregatedObject.Item: IJvDataItem;
begin
  Result := Owner as IJvDataItem;
end;

function TJvDataItemAggregatedObject.ItemImpl: TJvBaseDataItem;
begin
  Result := Owner as TJvBaseDataItem;
end;

{ TJvCustomDataItemsTextRenderer }

procedure TJvCustomDataItemsTextRenderer.DoDrawItem(ACanvas: TCanvas; var ARect: TRect;
  Item: IJvDataItem; State: TProviderDrawStates);
begin
  TJvDP_ProviderTextOnlyRender.Draw(Item, ACanvas, ARect, State);
end;

function TJvCustomDataItemsTextRenderer.DoMeasureItem(ACanvas: TCanvas; Item: IJvDataItem): TSize;
begin
  Result := TJvDP_ProviderTextOnlyRender.Measure(Item, ACanvas, []);
end;

function TJvCustomDataItemsTextRenderer.AvgItemSize(ACanvas: TCanvas): TSize;
begin
  Result := ACanvas.TextExtent('WyWyWyWyWyWyWyWyWyWy');
end;

{ TJvCustomDataItemsRenderer }

procedure TJvCustomDataItemsRenderer.DoDrawItem(ACanvas: TCanvas; var ARect: TRect;
  Item: IJvDataItem; State: TProviderDrawStates);
begin
  TJvDP_ProviderImgAndTextRender.Draw(Item, ACanvas, ARect, State);
(*  rgn := CreateRectRgn(0,0,0,0);
  GetClipRgn(ACanvas.handle, rgn);
  try
    IntersectClipRect(ACanvas.Handle, ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
    if Supports(Item, IJvDataItemText, TextIntf) then
      S := TextIntf.Caption
    else
      S := SDataItemRenderHasNoText;
    if Supports(Item.Items, IJvDataItemsImages, ImgsIntf) then
    begin
      if Supports(Item, IJvDataItemImage, ImgIntf) then
      begin
        if odSelected in State then
        begin
          ImgIdx := ImgIntf.SelectedIndex;
          if ImgIdx < 0 then
            ImgIdx := ImgIntf.ImageIndex;
        end
        else
        begin
          ImgIdx := ImgIntf.ImageIndex;
          if ImgIdx < 0 then
            ImgIdx := ImgIntf.SelectedIndex;
        end;
        if (ImgIdx > -1) and (TextIntf = nil) then
          S := '';
        // Apply alignment rules and render the image
        case ImgIntf.Alignment of
          taLeftJustify:
            begin
              ImgsIntf.Images.Draw(ACanvas, ARect.Left, ARect.Top, ImgIdx);
              Inc(ARect.Left, ImgsIntf.Images.Width + 2);
            end;
          taRightJustify:
            begin
              ImgsIntf.Images.Draw(ACanvas, ARect.Right - ImgsIntf.Images.Width, ARect.Top, ImgIdx);
              Dec(ARect.Right, ImgsIntf.Images.Width + 2);
            end;
          taCenter:
            begin
              ImgsIntf.Images.Draw(ACanvas, ARect.Left + ((ARect.Right - ARect.Left -
                ImgsIntf.Images.Width) div 2), ARect.Top, ImgIdx);
              Inc(ARect.Top, ImgsIntf.Images.Height + 2);
              ImgIdx := ACanvas.TextWidth(S);
              ARect.Left := ARect.Left + ((ARect.Right - ARect.Left - ImgIdx) div 2);
            end;
        end;
      end;
    end;
    ACanvas.TextRect(ARect, ARect.Left, ARect.Top, S);
  finally
    SelectClipRgn(ACanvas.Handle, rgn);
    DeleteObject(rgn);
  end;*)
end;

function TJvCustomDataItemsRenderer.DoMeasureItem(ACanvas: TCanvas; Item: IJvDataItem): TSize;
begin
  Result := TJvDP_ProviderImgAndTextRender.Measure(Item, ACanvas, []);
(*  if Supports(Item, IJvDataItemText, TextIntf) then
    S := TextIntf.Caption
  else
    S := SDataItemRenderHasNoText;
  Result := ACanvas.TextExtent(S);
  if Supports(Item.Items, IJvDataItemsImages, ImgsIntf) and (ImgsIntf.Images <> nil) then
  begin
    if Supports(Item, IJvDataItemImage, ImgIntf) then
    begin
      ImgIdx := ImgIntf.ImageIndex;
      if ImgIdx < 0 then
        ImgIdx := ImgIntf.SelectedIndex;
      if (ImgIdx > -1) and (TextIntf = nil) then
        S := '';
      // Apply alignment rules and render the image
      case ImgIntf.Alignment of
        taLeftJustify,
        taRightJustify:
          begin
            Result := ACanvas.TextExtent(S);
            Inc(Result.cx, ImgsIntf.Images.Width + 2);
            if ImgsIntf.Images.Height > Result.cy then
              Result.cy := ImgsIntf.Images.Height;
          end;
        taCenter:
          begin
            Result := ACanvas.TextExtent(S);
            Inc(Result.cy, ImgsIntf.Images.Height + 2);
            if ImgsIntf.Images.Width > Result.cx then
              Result.cx := ImgsIntf.Images.Width;
          end;
      end;
    end;
  end;*)
end;

function TJvCustomDataItemsRenderer.AvgItemSize(ACanvas: TCanvas): TSize;
begin
  Result := ACanvas.TextExtent('WyWyWyWyWyWyWyWyWyWy');
end;

{ TJvDataItemTextImpl }

function TJvDataItemTextImpl.GetCaption: string;
begin
  Result := FCaption;
end;

procedure TJvDataItemTextImpl.SetCaption(const Value: string);
begin
  if Caption <> Value then
  begin
    Item.Items.Provider.Changing(pcrUpdateItem, Item);
    FCaption := Value;
    Item.Items.Provider.Changed(pcrUpdateItem, Item);
  end;
end;

{ TJvDataItemImageImpl }

function TJvDataItemImageImpl.GetAlignment: TAlignment;
begin
  Result := FAlignment;
end;

procedure TJvDataItemImageImpl.SetAlignment(Value: TAlignment);
begin
  if GetAlignment <> Value then
  begin
    Item.Items.Provider.Changing(pcrUpdateItem, Item);
    FAlignment := Value;
    Item.Items.Provider.Changed(pcrUpdateItem, Item);
  end;
end;

function TJvDataItemImageImpl.GetImageIndex: Integer;
begin
  Result := FImageIndex;
end;

procedure TJvDataItemImageImpl.SetImageIndex(Index: Integer);
begin
  if GetImageIndex <> Index then
  begin
    Item.Items.Provider.Changing(pcrUpdateItem, Item);
    FImageIndex := Index;
    Item.Items.Provider.Changed(pcrUpdateItem, Item);
  end;
end;

function TJvDataItemImageImpl.GetSelectedIndex: Integer;
begin
  Result := FSelectedIndex;
end;

procedure TJvDataItemImageImpl.SetSelectedIndex(Value: Integer);
begin
  if GetSelectedIndex <> Value then
  begin
    Item.Items.Provider.Changing(pcrUpdateItem, Item);
    FSelectedIndex := Value;
    Item.Items.Provider.Changed(pcrUpdateItem, Item);
  end;
end;

{ TExtensibleInterfacedPersistent }

function TExtensibleInterfacedPersistent._AddRef: Integer;
begin
  Result := InterlockedIncrement(FRefCount);
end;

function TExtensibleInterfacedPersistent._Release: Integer;
begin
  Result := InterlockedDecrement(FRefCount);
  if Result = 0 then
    Destroy;
end;

function TExtensibleInterfacedPersistent.QueryInterface(const IID: TGUID; out Obj): HResult;
const
  E_NOINTERFACE = HResult($80004002);
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

procedure TExtensibleInterfacedPersistent.AddIntfImpl(const Obj: TAggregatedPersistentEx);
begin
  if IndexOfImplClass(TAggregatedPersistentExClass(Obj.ClassType)) >= 0 then
    raise EJVCLException.Create(SExtensibleIntObjDuplicateClass);
  FAdditionalIntfImpl.Add(Obj);
end;

procedure TExtensibleInterfacedPersistent.RemoveIntfImpl(const Obj: TAggregatedPersistentEx);
var
  I: Integer;
begin
  I := FAdditionalIntfImpl.IndexOf(Obj);
  if I > -1 then
  begin
    FAdditionalIntfImpl[I] := nil;
    Obj.Free;
    FAdditionalIntfImpl.Delete(I);
  end;
end;

function TExtensibleInterfacedPersistent.IndexOfImplClass(const AClass: TAggregatedPersistentExClass): Integer;
begin
  Result := FAdditionalIntfImpl.Count - 1;
  while (Result >= 0) and not (TObject(FAdditionalIntfImpl[Result]) is AClass) do
    Dec(Result);
end;

procedure TExtensibleInterfacedPersistent.ClearIntfImpl;
var
  I: Integer;
  Obj: TObject;
begin
  for I := FAdditionalIntfImpl.Count - 1 downto 0 do
  begin
    Obj := TObject(FAdditionalIntfImpl[I]);
    FAdditionalIntfImpl[I] := nil;
    Obj.Free;
    FAdditionalIntfImpl.Delete(I);
  end;
  FAdditionalIntfImpl.Clear;
end;

procedure TExtensibleInterfacedPersistent.InitImplementers;
begin
end;

procedure TExtensibleInterfacedPersistent.SuspendRefCount;
begin
  InterlockedIncrement(FRefCount);
end;

procedure TExtensibleInterfacedPersistent.ResumeRefCount;
begin
  InterlockedDecrement(FRefCount);
end;

function TExtensibleInterfacedPersistent.IsStreamableExtension(AnExtension: TAggregatedPersistentEx): Boolean;
begin
  Result := GetClass(AnExtension.ClassName) <> nil;
end;

procedure TExtensibleInterfacedPersistent.DefineProperties(Filer: TFiler);
var
  I: Integer;
begin
  inherited DefineProperties(Filer);
  I := FAdditionalIntfImpl.Count - 1;
  while (I >= 0) and not IsStreamableExtension(TAggregatedPersistentEx(FAdditionalIntfImpl[I])) do
    Dec(I);
  Filer.DefineProperty('Implementers', ReadImplementers, WriteImplementers, I >= 0);
end;

procedure TExtensibleInterfacedPersistent.ReadImplementers(Reader: TReader);
begin
  { When loading implementers the interface of this object maybe referenced. We don't want the
    instance destroyed yet, so reference counting will be suspended (by incrementing it) and resumed
    when we're done (by decrementing it without checking if it became zero) }
  SuspendRefCount;
  try
    if Reader.ReadValue <> vaCollection then
      raise EReadError.Create(SExtensibleIntObjCollectionExpected);
    while not Reader.EndOfList do
      ReadImplementer(Reader);
    Reader.ReadListEnd;
  finally
    ResumeRefCount;
  end;
end;

procedure TExtensibleInterfacedPersistent.WriteImplementers(Writer: TWriter);
var
  I: Integer;
  SavePropPath: string;
begin
  TOpenWriter(Writer).WriteValue(vaCollection);
  SavePropPath := TOpenWriter(Writer).PropPath;
  TOpenWriter(Writer).PropPath := '';
  try
    for I := 0 to FAdditionalIntfImpl.Count - 1 do
      if IsStreamableExtension(TAggregatedPersistentEx(FAdditionalIntfImpl[I])) then
        WriteImplementer(Writer, TAggregatedPersistentEx(FAdditionalIntfImpl[I]));
    Writer.WriteListEnd;
  finally
    TOpenWriter(Writer).PropPath := SavePropPath;
  end;
end;

procedure TExtensibleInterfacedPersistent.ReadImplementer(Reader: TReader);
var
  ClassName: string;
  ClassType: TPersistentClass;
  I: Integer;
  Impl: TAggregatedPersistentEx;
begin
  Reader.ReadListBegin;
  ClassName := Reader.ReadStr;
  if not AnsiSameText(ClassName, 'ClassName') then
    raise EReadError.Create(SExtensibleIntObjClassNameExpected);
  ClassName := Reader.ReadString;
  ClassType := FindClass(ClassName);
  if not ClassType.InheritsFrom(TAggregatedPersistentEx) then
    raise EReadError.Create(SExtensibleIntObjInvalidClass);
  I := IndexOfImplClass(TAggregatedPersistentExClass(ClassType));
  if I >= 0 then
    Impl := TAggregatedPersistentEx(FAdditionalIntfImpl[I])
  else
    Impl := TAggregatedPersistentExClass(ClassType).Create(Self);
  while not Reader.EndOfList do
    TOpenReader(Reader).ReadProperty(Impl);
  Reader.ReadListEnd;
end;

procedure TExtensibleInterfacedPersistent.WriteImplementer(Writer: TWriter;
  Instance: TAggregatedPersistentEx);
begin
  Writer.WriteListBegin;
  TOpenWriter(Writer).WritePropName('ClassName');
  Writer.WriteString(Instance.ClassName);
  TOpenWriter(Writer).WriteProperties(Instance);
  Writer.WriteListEnd;
end;

constructor TExtensibleInterfacedPersistent.Create;
begin
  inherited Create;
  FAdditionalIntfImpl := TList.Create;
end;

destructor TExtensibleInterfacedPersistent.Destroy;
begin
  ClearIntfImpl;
  FreeAndNil(FAdditionalIntfImpl);
  inherited Destroy;
end;

procedure TExtensibleInterfacedPersistent.AfterConstruction;
begin
  inherited AfterConstruction;
  InitImplementers;
// Release the constructor's implicit refcount
  InterlockedDecrement(FRefCount);
end;

procedure TExtensibleInterfacedPersistent.BeforeDestruction;
begin
  if RefCount <> 0 then RunError(2);
  inherited BeforeDestruction;
end;

function TExtensibleInterfacedPersistent.GetInterface(const IID: TGUID; out Obj): Boolean;
var
  I: Integer;
begin
  Result := inherited GetInterface(IID, Obj);
  if not Result then
  begin
    I := FAdditionalIntfImpl.Count - 1;
    while (I >= 0) and ((FAdditionalIntfImpl[I] = nil) or
        not TAggregatedPersistentEx(FAdditionalIntfImpl[I]).GetInterface(IID, Obj)) do
      Dec(I);
    Result := I >= 0;
  end;
end;

class function TExtensibleInterfacedPersistent.NewInstance: TObject;
begin
  Result := inherited NewInstance;
  // set a refcount to avoid destruction due to refcounting during construction
  TExtensibleInterfacedPersistent(Result).FRefCount := 1;
end;

{ TAggregatedPersistent }

function TAggregatedPersistent.GetController: IUnknown;
begin
  Result := IUnknown(FController);
end;

function TAggregatedPersistent.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := Controller.QueryInterface(IID, Obj);
end;

function TAggregatedPersistent._AddRef: Integer;
begin
  Result := Controller._AddRef;
end;

function TAggregatedPersistent._Release: Integer;
begin
  Result := Controller._Release;
end;

constructor TAggregatedPersistent.Create(Controller: IUnknown);
begin
  inherited Create;
  FController := Pointer(Controller);
end;

{ TAggregatedPersistentEx }

constructor TAggregatedPersistentEx.Create(AOwner: TExtensibleInterfacedPersistent);
begin
  inherited Create(AOwner);
  FOwner := AOwner;
end;

procedure TAggregatedPersistentEx.AfterConstruction;
begin
  inherited AfterConstruction;
  FOwner.AddIntfImpl(Self);
end;

procedure TAggregatedPersistentEx.BeforeDestruction;
var
  I: Integer;
begin
  inherited BeforeDestruction;
  I := FOwner.FAdditionalIntfImpl.IndexOf(Self);
  if I >= 0 then
    FOwner.FAdditionalIntfImpl.Delete(I);
end;

function TAggregatedPersistentEx.GetInterface(const IID: TGUID; out Obj): Boolean;
begin
  Result := inherited GetInterface(IID, Obj);
end;

//===TJvProviderNotification========================================================================

function TJvProviderNotification._AddRef: Integer;
begin
  Result := -1;
end;

function TJvProviderNotification._Release: Integer;
begin
  Result := -1;
end;

function TJvProviderNotification.QueryInterface(const IID: TGUID; out Obj): HResult;
const
  E_NOINTERFACE = HResult($80004002);
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

procedure TJvProviderNotification.DataProviderChanging(const ADataProvider: IJvDataProvider;
  AReason: TDataProviderChangeReason; Source: IUnknown);
begin
  if @FOnChanging <> nil then
    FOnChanging(ADataProvider, AReason, Source);
end;

procedure TJvProviderNotification.DataProviderChanged(const ADataProvider: IJvDataProvider;
  AReason: TDataProviderChangeReason; Source: IUnknown);
begin
  if @FOnChanged <> nil then
    FOnChanged(ADataProvider, AReason, Source);
end;

{ TJvBaseDataItems }

function TJvBaseDataItems.IsStreamableItem(Item: IJvDataItem): Boolean;
var
  AClass: TPersistentClass;
begin
  AClass := GetClass(Item.GetImplementer.ClassName);
  Result := (AClass <> nil) and AClass.InheritsFrom(TJvBaseDataItem);
end;

procedure TJvBaseDataItems.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineProperty('Items', ReadItems, WriteItems, True);
end;

procedure TJvBaseDataItems.ReadItems(Reader: TReader);
begin
  if Reader.ReadValue <> vaCollection then
    raise EReadError.Create(SExtensibleIntObjCollectionExpected);
  while not Reader.EndOfList do
    ReadItem(Reader);
  Reader.ReadListEnd;
end;

procedure TJvBaseDataItems.WriteItems(Writer: TWriter);
var
  I: Integer;
  SavePropPath: string;
begin
  TOpenWriter(Writer).WriteValue(vaCollection);
  SavePropPath := TOpenWriter(Writer).PropPath;
  TOpenWriter(Writer).PropPath := '';
  try
    for I := 0 to getCount - 1 do
    begin
      if IsStreamableItem(getItem(I)) then
        WriteItem(Writer, getItem(I));
    end;
    Writer.WriteListEnd;
  finally
    TOpenWriter(Writer).PropPath := SavePropPath;
  end;
end;

procedure TJvBaseDataItems.ReadItem(Reader: TReader);
var
  PropName: string;
  ClassName: string;
  PerstClass: TPersistentClass;
  ItemClass: TJvBaseDataItemClass;
  ItemInstance: TJvBaseDataItem;
begin
  Reader.ReadListBegin;
  PropName := Reader.ReadStr;
  if not AnsiSameText(PropName, 'ClassName') then
    raise EReadError.Create(SExtensibleIntObjClassNameExpected);
  ClassName := Reader.ReadString;
  PerstClass := FindClass(ClassName);
  if not PerstClass.InheritsFrom(TJvBaseDataItem) then
    raise EReadError.Create(SExtensibleIntObjInvalidClass);
  ItemClass := TJvBaseDataItemClass(PerstClass);
  ItemInstance := ItemClass.Create(Self);
  try
    InternalAdd(ItemInstance);
  except
    ItemInstance.Free;
    raise;
  end;
  while not Reader.EndOfList do
    TOpenReader(Reader).ReadProperty(ItemInstance);
  Reader.ReadListEnd;
end;

procedure TJvBaseDataItems.WriteItem(Writer: TWriter; Item: IJvDataItem);
var
  Inst: TPersistent;
begin
  Writer.WriteListBegin;
  Inst := TPersistent(Item.GetImplementer);
  Writer.WriteStr('ClassName');
  Writer.WriteString(Inst.ClassName);
  TOpenWriter(Writer).WriteProperties(Inst);
  Writer.WriteListEnd;
end;

function TJvBaseDataItems.GetParent: IJvDataItem;
begin
  Result := IJvDataItem(FParent);
end;

function TJvBaseDataItems.GetProvider: IJvDataProvider;
begin
  Result := FProvider;
end;

function TJvBaseDataItems.GetImplementer: TObject;
begin
  Result := Self;
end;

function TJvBaseDataItems.IsDynamic: Boolean;
begin
  Result := True;
end;

function TJvBaseDataItems.FindByID(ID: string; const Recursive: Boolean): IJvDataItem;
var
  I: Integer;
  SubItems: IJvDataItems;
  Search: IJvDataIDSearch;
begin
  I := GetCount - 1;
  while (I >= 0) and (GetItem(I).GetID <> ID) do
    Dec(I);
  if I >= 0 then
    Result := GetItem(I)
  else
  begin
    Result := nil;
    if Recursive then
    begin
      I := GetCount - 1;
      while (I >= 0) and (Result = nil) do
      begin
        if Supports(GetItem(I), IJvDataItems, SubItems) then
        begin
          if Supports(SubItems, IJvDataIDSearch, Search) then
            Result := Search.Find(ID, Recursive);
        end;
        Dec(I);
      end;
    end;
  end;
end;

constructor TJvBaseDataItems.Create;
begin
  inherited Create;
end;

constructor TJvBaseDataItems.CreateProvider(const Provider: IJvDataProvider);
begin
  Create;
  FProvider := Provider;
end;

constructor TJvBaseDataItems.CreateParent(const Parent: IJvDataItem);
begin
  CreateProvider(Parent.Items.Provider);
  FParent := Pointer(Parent);
  if (Parent <> nil) and Parent.Items.IsDynamic then
    FParentIntf := Parent;
  if (Parent <> nil) and (Parent.GetImplementer is TExtensibleInterfacedPersistent) then
    FSubAggregate := TJvBaseDataItemSubItems.Create(
      TExtensibleInterfacedPersistent(Parent.GetImplementer), Self);
end;

procedure TJvBaseDataItems.BeforeDestruction;
begin
  inherited BeforeDestruction;
  if FSubAggregate <> nil then
    FreeAndNil(FSubAggregate);
end;

{ TJvBaseDataItemSubItems }

constructor TJvBaseDataItemSubItems.Create(AOwner: TExtensibleInterfacedPersistent;
  AItems: TJvBaseDataItems);
begin
  inherited Create(AOwner);
  FItems := AItems;
end;

destructor TJvBaseDataItemSubItems.Destroy;
begin
  inherited Destroy;
end;

procedure TJvBaseDataItemSubItems.BeforeDestruction;
begin
  inherited BeforeDestruction;
  if FItems.GetImplementer is TJvBaseDataItems then
    TJvBaseDataItems(FItems.GetImplementer).FSubAggregate := nil;
end;

function TJvBaseDataItemSubItems.GetInterface(const IID: TGUID; out Obj): Boolean;
begin
  Result := inherited GetInterface(IID, Obj) or Succeeded(FItems.QueryInterface(IID, Obj));
end;

{ TJvCustomDataItemTextRenderer }

procedure TJvCustomDataItemTextRenderer.Draw(ACanvas: TCanvas; var ARect: TRect; State: TProviderDrawStates);
begin
  TJvDP_ProviderTextOnlyRender.Draw(Item, ACanvas, ARect, State);
end;

function TJvCustomDataItemTextRenderer.Measure(ACanvas: TCanvas): TSize;
begin
  Result := TJvDP_ProviderTextOnlyRender.Measure(Item, ACanvas, []);
end;

{ TJvCustomDataItemRenderer }

procedure TJvCustomDataItemRenderer.Draw(ACanvas: TCanvas; var ARect: TRect; State: TProviderDrawStates);
begin
  TJvDP_ProviderImgAndTextRender.Draw(Item, ACanvas, ARect, State);
(*  rgn := CreateRectRgn(0,0,0,0);
  GetClipRgn(ACanvas.handle, rgn);
  try
    IntersectClipRect(ACanvas.Handle, ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
    if Supports(Item, IJvDataItemText, TxtIntf) then
      S := TxtIntf.Caption
    else
      S := SDataItemRenderHasNoText;
    if Supports(Item.Items, IJvDataItemsImages, ImgsIntf) and (ImgsIntf.Images <> nil) and
      Supports(Item, IJvDataItemImage, ImgIntf) then
    begin
      ImgIdx := ImgIntf.ImageIndex;
      if (ImgIdx < 0) or ((odSelected in State) and (ImgIntf.SelectedIndex >= 0)) then
        ImgIdx := ImgIntf.SelectedIndex;
      if (ImgIdx >= 0) and (TxtIntf = nil) then
        S := '';
      if ImgIdx >= 0 then
      begin
        case ImgIntf.Alignment of
          taLeftJustify:
            begin
              ImgsIntf.Images.Draw(ACanvas, ARect.Left, ARect.Top, ImgIdx);
              Inc(ARect.Left, 2 + ImgsIntf.Images.Width);
            end;
          taRightJustify:
            begin
              ImgsIntf.Images.Draw(ACanvas, ARect.Right - ImgsIntf.Images.Width, ARect.Top, ImgIdx);
              Dec(ARect.Right, 2 + ImgsIntf.Images.Width);
            end;
          taCenter:
            begin
              ImgsIntf.Images.Draw(ACanvas, ARect.Left + ((ARect.Right - ARect.Left -
                ImgsIntf.Images.Width) div 2), ARect.Top, ImgIdx);
              Inc(ARect.Top, ImgsIntf.Images.Height + 2);
              ImgIdx := ACanvas.TextWidth(S);
              ARect.Left := ARect.Left + ((ARect.Right - ARect.Left - ImgIdx) div 2);
            end;
        end;
      end;
    end;
    ACanvas.TextRect(ARect, ARect.Left, ARect.Top, S);
  finally
    SelectClipRgn(ACanvas.Handle, rgn);
    DeleteObject(rgn);
  end;*)
end;

function TJvCustomDataItemRenderer.Measure(ACanvas: TCanvas): TSize;
begin
  Result := TJvDP_ProviderImgAndTextRender.Measure(Item, ACanvas, []);
(*  if Supports(Item, IJvDataItemText, TxtIntf) then
    S := TxtIntf.Caption
  else
    S := SDataItemRenderHasNoText;
  Result := ACanvas.TextExtent(S);
  if Supports(Item.Items, IJvDataItemsImages, ImgsIntf) and (ImgsIntf.Images <> nil) and
    Supports(Item, IJvDataItemImage, ImgIntf) then
  begin
    ImgIdx := ImgIntf.ImageIndex;
    if (ImgIdx < 0) then
      ImgIdx := ImgIntf.SelectedIndex;
    if (ImgIdx >= 0) and (TxtIntf = nil) then
      S := '';
    if ImgIdx >= 0 then
      case ImgIntf.Alignment of
        taLeftJustify,
        taRightJustify:
          begin
            Result := ACanvas.TextExtent(S);
            Inc(Result.cx, ImgsIntf.Images.Width + 2);
            if ImgsIntf.Images.Height > Result.cy then
              Result.cy := ImgsIntf.Images.Height;
          end;
        taCenter:
          begin
            Result := ACanvas.TextExtent(S);
            Inc(Result.cy, ImgsIntf.Images.Height + 2);
            if ImgsIntf.Images.Width > Result.cx then
              Result.cx := ImgsIntf.Images.Width;
          end;
      end;
  end;*)
end;

{ TJvCustomDataItemStates }

procedure TJvCustomDataItemStates.InitStatesUsage(UseEnabled, UseChecked, UseVisible: Boolean);
begin
  if UseEnabled then
    FEnabled := disTrue
  else
    FEnabled := disNotUsed;
  if UseChecked then
    FChecked := disFalse
  else
    FChecked := disNotUsed;
  if UseVisible then
    FVisible := disTrue
  else
    FVisible := disNotUsed;
end;

function TJvCustomDataItemStates.Get_Enabled: TDataItemState;
begin
  Result := FEnabled;
end;

procedure TJvCustomDataItemStates.Set_Enabled(Value: TDataItemState);
begin
  if Value = disNotUsed then Exit;
  if Value <> Get_Enabled then
  begin
    Item.Items.Provider.Changing(pcrUpdateItem, Item);
    FEnabled := Value;
    Item.Items.Provider.Changed(pcrUpdateItem, Item);
  end;
end;

function TJvCustomDataItemStates.Get_Checked: TDataItemState;
begin
  Result := FChecked;
end;

procedure TJvCustomDataItemStates.Set_Checked(Value: TDataItemState);
begin
  if Value = disNotUsed then Exit;
  if Value <> Get_Checked then
  begin
    Item.Items.Provider.Changing(pcrUpdateItem, Item);
    FChecked := Value;
    Item.Items.Provider.Changed(pcrUpdateItem, Item);
  end;
end;

function TJvCustomDataItemStates.Get_Visible: TDataItemState;
begin
  Result := FVisible;
end;

procedure TJvCustomDataItemStates.Set_Visible(Value: TDataItemState);
begin
  if Value = disNotUsed then Exit;
  if Value <> Get_Visible then
  begin
    Item.Items.Provider.Changing(pcrUpdateItem, Item);
    FVisible := Value;
    Item.Items.Provider.Changed(pcrUpdateItem, Item);
  end;
end;

{ TJvDataItemsAggregatedObject }

function TJvDataItemsAggregatedObject.Items: IJvDataItems;
begin
  Result := Owner as IJvDataItems;
end;

function TJvDataItemsAggregatedObject.ItemsImpl: TJvBaseDataItems;
begin
  Result := Owner as TJvBaseDataItems;
end;

{ TJvBaseDataItemsRenderer }

procedure TJvBaseDataItemsRenderer.DrawItemByIndex(ACanvas: TCanvas; var ARect: TRect;
  Index: Integer; State: TProviderDrawStates);
begin
  if (Index < 0) or (Index >= Items.Count) then
    raise EJVCLException.CreateFmt(SListIndexError, [Index]);
  DrawItem(ACanvas, ARect, Items.Items[Index], State);
end;

function TJvBaseDataItemsRenderer.MeasureItemByIndex(ACanvas: TCanvas; Index: Integer): TSize;
begin
  if Index = -1 then
    Result := AvgItemSize(ACanvas)
  else
  begin
    if (Index < 0) or (Index >= Items.Count) then
      raise EJVCLException.CreateFmt(SListIndexError, [Index]);
    Result := MeasureItem(ACanvas, Items.Items[Index]);
  end;
end;

procedure TJvBaseDataItemsRenderer.DrawItem(ACanvas: TCanvas; var ARect: TRect; Item: IJvDataItem;
  State: TProviderDrawStates);
var
  ImgRender: IJvDataItemRenderer;
begin
  if Supports(Item, IJvDataItemRenderer, ImgRender) then
    ImgRender.Draw(ACanvas, ARect, State)
  else
    DoDrawItem(ACanvas, ARect, Item, State);
end;

function TJvBaseDataItemsRenderer.MeasureItem(ACanvas: TCanvas; Item: IJvDataItem): TSize;
var
  ImgRender: IJvDataItemRenderer;
begin
  if Supports(Item, IJvDataItemRenderer, ImgRender) then
    Result := ImgRender.Measure(ACanvas)
  else
    Result := DoMeasureItem(ACanvas, Item);
end;

{ TJvDataItemsList }

procedure TJvDataItemsList.InternalAdd(Item: IJvDataItem);
begin
  List.Add(Item.GetImplementer);
end;

function TJvDataItemsList.IsDynamic: Boolean;
begin
  Result := False;
end;

function TJvDataItemsList.GetCount: Integer;
begin
  Result := List.Count;
end;

function TJvDataItemsList.GetItem(I: Integer): IJvDataItem;
begin
  Result := (List[I] as TJvBaseDataItem) as IJvDataItem;
end;

procedure TJvDataItemsList.AfterConstruction;
begin
  inherited AfterConstruction;
  FList := TObjectList.Create;
end;

procedure TJvDataItemsList.BeforeDestruction;
begin
  inherited BeforeDestruction;
  FList.Free;
end;

{ TJvBaseDataItemsListManagement }

function TJvBaseDataItemsListManagement.Add(Item: IJvDataItem): IJvDataItem;
begin
  Items.Provider.Changing(pcrAdd, Items);
  TJvDataItemsList(ItemsImpl).List.Add(Item.GetImplementer);
  Result := Item;
  Items.Provider.Changed(pcrAdd, Result);
end;

procedure TJvBaseDataItemsListManagement.Clear;
begin
  Items.Provider.Changing(pcrUpdateItems, Items);
  TJvDataItemsList(ItemsImpl).List.Clear;
  Items.Provider.Changed(pcrUpdateItems, Items);
end;

procedure TJvBaseDataItemsListManagement.Delete(Index: Integer);
begin
  Items.Provider.Changing(pcrDelete, Items.GetItem(Index));
  TJvDataItemsList(ItemsImpl).List.Delete(Index);
  Items.Provider.Changed(pcrDelete, nil);
end;

procedure TJvBaseDataItemsListManagement.Remove(Item: IJvDataItem);
var
  Impl: TObject;
begin
  Items.Provider.Changing(pcrDelete, Item);
  Impl := Item.GetImplementer;
  if (Impl is TExtensibleInterfacedPersistent) and
      (TExtensibleInterfacedPersistent(Impl).RefCount = 0) then
    Pointer(Item) := nil;
  TJvDataItemsList(ItemsImpl).List.Remove(Impl);
  Items.Provider.Changed(pcrDelete, nil);
end;

{ TJvCustomDataItemsImages }

function TJvCustomDataItemsImages.GetDisabledImages: TCustomImageList;
begin
  Result := FDisabledImages;
end;

procedure TJvCustomDataItemsImages.SetDisabledImages(const Value: TCustomImageList);
begin
  if Value <> GetDisabledImages then
  begin
    (Owner as IJvDataItems).Provider.Changing(pcrUpdateItems, Items);
    FDisabledImages := Value;
    (Owner as IJvDataItems).Provider.Changed(pcrUpdateItems, Items);
  end;
end;

function TJvCustomDataItemsImages.GetHotImages: TCustomImageList;
begin
  Result := FHotImages;
end;

procedure TJvCustomDataItemsImages.SetHotImages(const Value: TCustomImageList);
begin
  if Value <> GetHotImages then
  begin
    (Owner as IJvDataItems).Provider.Changing(pcrUpdateItems, Items);
    FHotImages := Value;
    (Owner as IJvDataItems).Provider.Changed(pcrUpdateItems, Items);
  end;
end;

function TJvCustomDataItemsImages.GetImages: TCustomImageList;
begin
  Result := FImages;
end;

procedure TJvCustomDataItemsImages.SetImages(const Value: TCustomImageList);
begin
  if Value <> GetImages then
  begin
    (Owner as IJvDataItems).Provider.Changing(pcrUpdateItems, Items);
    FImages := Value;
    (Owner as IJvDataItems).Provider.Changed(pcrUpdateItems, Items);
  end;
end;

{ TJvBaseDataItem }

procedure TJvBaseDataItem.InitID;
var
  G: TGUID;
begin
  CoCreateGuid(G);
  FID := HexBytes(G, SizeOf(G));
end;

procedure TJvBaseDataItem.SetID(Value: string);
begin
  FID := Value;
end;

function TJvBaseDataItem._AddRef: Integer;
begin
  if Items.IsDynamic then
    Result := inherited _AddRef
  else
    Result := -1;
end;

function TJvBaseDataItem._Release: Integer;
begin
  if Items.IsDynamic then
    Result := inherited _Release
  else
    Result := -1;
end;

procedure TJvBaseDataItem.DefineProperties(Filer: TFiler);
var
  Tmp: IJvDataItems;
begin
  inherited DefineProperties(Filer);
  Filer.DefineProperty('SubItems', ReadSubItems, WriteSubItems,
    Supports(Self as IJvDataItem, IJvDataItems, Tmp));
end;

procedure TJvBaseDataItem.ReadSubItems(Reader: TReader);
var
  PropName: string;
  ClassName: string;
  AClass: TPersistentClass;
  I: Integer;
begin
  { When loading sub items the interface of this object may be referenced. We don't want the
    instance destroyed yet, so reference counting will be suspended (by incrementing it) and resumed
    when we're done (by decrementing it without checking if it became zero) }
  SuspendRefCount;
  try
    if Reader.ReadValue <> vaCollection then
      raise EReadError.Create(SExtensibleIntObjCollectionExpected);
    Reader.ReadListBegin;
    PropName := Reader.ReadStr;
    if not AnsiSameText(PropName, 'ClassName') then
      raise EReadError.Create(SExtensibleIntObjClassNameExpected);
    ClassName := Reader.ReadString;
    AClass := FindClass(ClassName);
    if not AClass.InheritsFrom(TJvBaseDataItems) then
      raise EReadError.Create(SExtensibleIntObjInvalidClass);
    I := IndexOfImplClass(TJvBaseDataItemSubItems);
    if I > -1 then
    begin
      if TJvBaseDataItemSubItems(FAdditionalIntfImpl[I]).Items.GetImplementer.ClassType <> AClass then
      begin
        FAdditionalIntfImpl.Delete(I);
        I := -1;
      end;
    end;
    if I = -1 then
    begin
      TJvDataItemsClass(AClass).CreateParent(Self);
      I := IndexOfImplClass(TJvBaseDataItemSubItems);
    end;
    while not Reader.EndOfList do
      TOpenReader(Reader).ReadProperty(
        TJvBaseDataItems(TJvBaseDataItemSubItems(FAdditionalIntfImpl[I]).Items.GetImplementer));
    Reader.ReadListEnd;
    Reader.ReadListEnd;
  finally
    ResumeRefCount;
  end;
end;

procedure TJvBaseDataItem.WriteSubItems(Writer: TWriter);
var
  Items: IJvDataItems;
  SavePropPath: string;
begin
  QueryInterface(IJvDataItems, Items);
  TOpenWriter(Writer).WriteValue(vaCollection);
  SavePropPath := TOpenWriter(Writer).PropPath;
  TOpenWriter(Writer).PropPath := '';
  try
    Writer.WriteListBegin;
    Writer.WriteStr('ClassName');
    Writer.WriteString(Items.GetImplementer.ClassName);
    TOpenWriter(Writer).WriteProperties(Items.GetImplementer as TPersistent);
    Writer.WriteListEnd;
    Writer.WriteListEnd;
  finally
    TOpenWriter(Writer).PropPath := SavePropPath;
  end;
end;

function TJvBaseDataItem.GetItems: IJvDataItems;
begin
  Result := IJvDataItems(FItems);
end;

function TJvBaseDataItem.GetImplementer: TObject;
begin
  Result := Self;
end;

function TJvBaseDataItem.GetID: string;
begin
  Result := FID;
end;

constructor TJvBaseDataItem.Create(AOwner: IJvDataItems);
begin
  inherited Create;
  FItems := Pointer(AOwner);
  // Dynamically generated items will need a hard reference to the IJvDataItems owner.
  if AOwner.IsDynamic then
    FItemsIntf := AOwner;
end;

procedure TJvBaseDataItem.AfterConstruction;
begin
  InitID;
  inherited AfterConstruction;
end;

{ TJvCustomDataProvider }

function TJvCustomDataProvider.QueryInterface(const IID: TGUID; out Obj): HResult;
const
  E_NOINTERFACE = HResult($80004002);
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

procedure TJvCustomDataProvider.Changing(ChangeReason: TDataProviderChangeReason; Source: IUnknown);
var
  I: Integer;
begin
  for I := 0 to FNotifiers.Count - 1 do
    (FNotifiers[I] as IJvDataProviderNotify).DataProviderChanging(Self, ChangeReason, Source);
end;

procedure TJvCustomDataProvider.Changed(ChangeReason: TDataProviderChangeReason; Source: IUnknown);
var
  I: Integer;
begin
  for I := 0 to FNotifiers.Count - 1 do
    (FNotifiers[I] as IJvDataProviderNotify).DataProviderChanged(Self, ChangeReason, Source);
end;

class function TJvCustomDataProvider.PersistentDataItems: Boolean;
begin
  Result := False;
end;

class function TJvCustomDataProvider.ItemsClass: TJvDataItemsClass;
begin
  Result := TJvDataItemsList;
end;

procedure TJvCustomDataProvider.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  if PersistentDataItems then
    Filer.DefineProperty('Root', ReadRoot, WriteRoot, True);
end;

procedure TJvCustomDataProvider.ReadRoot(Reader: TReader);
begin
  if Reader.ReadValue <> vaCollection then
    raise EReadError.Create(SExtensibleIntObjCollectionExpected);
  Reader.ReadListBegin;
  // We don''t really have a root item; just stream in the DataItemsImpl instance.
  while not Reader.EndOfList do
    TOpenReader(Reader).ReadProperty(DataItemsImpl);
  Reader.ReadListEnd;
  Reader.ReadListEnd;
end;

procedure TJvCustomDataProvider.WriteRoot(Writer: TWriter);
begin
  TOpenWriter(Writer).WriteValue(vaCollection);
  Writer.WriteListBegin;
  // We don''t really have a root item; just stream out the DataItemsImpl instance.
  TOpenWriter(Writer).WriteProperties(DataItemsImpl);
  Writer.WriteListEnd;
  Writer.WriteListEnd;
end;

procedure TJvCustomDataProvider.AddToArray(var ClassArray: TClassArray; AClass: TClass);
begin
  SetLength(ClassArray, Length(ClassArray) + 1);
  ClassArray[High(ClassArray)] := AClass;
end;

procedure TJvCustomDataProvider.DeleteFromArray(var ClassArray: TClassArray; Index: Integer);
begin
  if (Index >= 0) and (Index <= High(ClassArray)) then
  begin
    if Index < High(ClassArray) then
      Move(ClassArray[Index + 1], ClassArray[Index], SizeOf(TClass) * (High(ClassArray) - Index));
    SetLength(ClassArray, High(ClassArray));
  end;
end;

function TJvCustomDataProvider.IndexOfClass(AClassArray: TClassArray; AClass: TClass): Integer;
begin
  Result := High(AClassArray);
  while (Result >= 0) and (AClassArray[Result] <> AClass) do
    Dec(Result);
end;

procedure TJvCustomDataProvider.RemoveFromArray(var ClassArray: TClassArray; AClass: TClass);
var
  I: Integer;
begin
  I := IndexOfClass(ClassArray, AClass);
  if I > -1 then
    DeleteFromArray(ClassArray, I);
end;

function TJvCustomDataProvider.IsTreeProvider: Boolean;
var
  I: Integer;
  Obj: IJvDataItems;
begin
  I := GetItems.Count - 1;
  while (I >= 0) and not Supports(GetItems.GetItem(I), IJvDataItems, Obj) do
    Dec(I);
  Result := I >= 0;
end;

{$IFNDEF COMPILER6_UP}
function TJvCustomDataProvider.GetComponent: TComponent;
begin
  Result := Self;
end;
{$ENDIF COMPILER6_UP}

function TJvCustomDataProvider.GetItems: IJvDataItems;
begin
  Result := DataItemsImpl;
end;

procedure TJvCustomDataProvider.RegisterChangeNotify(ANotify: IJvDataProviderNotify);
begin
  if FNotifiers.IndexOf(ANotify) < 0 then
    FNotifiers.Add(ANotify);
end;

procedure TJvCustomDataProvider.UnregisterChangeNotify(ANotify: IJvDataProviderNotify);
begin
  FNotifiers.Remove(ANotify);
end;

function TJvCustomDataProvider.ConsumerClasses: TClassArray;
var
  Obj: IUnknown;
begin
  SetLength(Result, 0);

  // Generic provider based extensions
  if Supports(Self, IJvDataContexts, Obj) then
    AddToArray(Result, TJvDataConsumerContext);

  // Consumer based extensions
  if SelectedConsumer <> nil then
  begin
    // Generic consumer based extensions
    if SelectedConsumer.AttributeApplies(DPA_RendersSingleItem) or IsTreeProvider then
      AddToArray(Result, TJvDataConsumerItemSelect);
    if SelectedConsumer.AttributeApplies(DPA_ConsumerDisplaysList) then
      AddToArray(Result, TJvDataConsumerViewList);
  end;
end;

procedure TJvCustomDataProvider.SelectConsumer(Consumer: IJvDataConsumer);
begin
  if FConsumerStack <> nil then
    FConsumerStack.Insert(0, Consumer);
end;

function TJvCustomDataProvider.SelectedConsumer: IJvDataConsumer;
begin
  if (FConsumerStack <> nil) and (FConsumerStack.Count > 0) then
    Result := IJvDataConsumer(FConsumerStack[0])
  else
    Result := nil;
end;

procedure TJvCustomDataProvider.ReleaseConsumer;
begin
  if (FConsumerStack <> nil) and (FConsumerStack.Count > 0) then
    FConsumerStack.Delete(0)
  else if FConsumerStack <> nil then
    raise EJVCLException.Create('Consumer stack is empty.');
end;

procedure TJvCustomDataProvider.SelectContext(Context: IJvDataContext);
begin
  if FContextStack <> nil then
  FContextStack.Insert(0, Context);
end;

function TJvCustomDataProvider.SelectedContext: IJvDataContext;
begin
  if (FContextStack <> nil) and (FContextStack.Count > 0) then
    Result := IJvDataContext(FContextStack[0])
  else
    Result := nil; //TODO: Return the providers implicit context
end;

procedure TJvCustomDataProvider.ReleaseContext;
begin
  if (FContextStack <> nil) and (FContextStack.Count > 0) then
    FContextStack.Delete(0)
  else if FContextStack <> nil then
    raise EJVCLException.Create('Context stack is empty.');
end;

constructor TJvCustomDataProvider.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FNotifiers := TInterfaceList.Create;
  FConsumerStack := TInterfaceList.Create;
  FContextStack := TInterfaceList.Create;
  if ItemsClass <> nil then
    FDataItemsImpl := ItemsClass.CreateProvider(Self)
  else
    raise EJVCLException.Create(SDataProviderNeedsItemsImpl);
  FDataItemsImpl._AddRef;
end;

destructor TJvCustomDataProvider.Destroy;
begin
  FreeAndNil(FNotifiers);
  FreeAndNil(FConsumerStack);
  FreeAndNil(FContextStack);
  FDataItemsImpl._Release;
  inherited Destroy;
end;

procedure TJvCustomDataProvider.BeforeDestruction;
begin
  if (FDataItemsImpl <> nil) and (FDataItemsImpl.RefCount > 1) then
    RunError(2);
  inherited BeforeDestruction;
  Changing(pcrDestroy);
end;

function TJvCustomDataProvider.GetInterface(const IID: TGUID; out Obj): Boolean;
begin
  Result := inherited GetInterface(IID, Obj) or (FDataItemsImpl.GetInterface(IID, Obj));
end;

{ TJvDataConsumer }

procedure TJvDataConsumer.SetProvider(Value: IJvDataProvider);
begin
  if FProvider <> Value then
  begin
    if FProvider <> nil then
      FProvider.UnregisterChangeNotify(Self);
    ProviderChanging;
    FProvider := Value;
    if FProvider <> nil then
      FProvider.RegisterChangeNotify(Self);
    ProviderChanged;
    if FFixupContext <> '' then
    begin
      Context := FFixupContext;
      FFixupContext := '';
    end
    else
      SetContextIntf(nil);
    if FNeedFixups then
    begin
      FixupExtensions;
      FNeedFixups := False;
    end;
    Changed;
  end;
end;

{$IFNDEF COMPILER6_UP}
function TJvDataConsumer.GetProviderComp: TComponent;
var
  CompRef: IInterfaceComponentReference;
begin
  if FProvider = nil then
    Result := nil
  else
  begin
    if Succeeded(FProvider.QueryInterface(IInterfaceComponentReference, CompRef)) then
      Result := CompRef.GetComponent as TComponent
    else
      Result := nil;
  end;
end;

procedure TJvDataConsumer.SetProviderComp(Value: TComponent);
var
  CompRef: IInterfaceComponentReference;
  ProviderRef: IJvDataProvider;
begin
  if Value = nil then
    SetProvider(nil)
  else
  begin
    if Value.GetInterface(IInterfaceComponentReference, CompRef) then
    begin
      if Value.GetInterface(IJvDataProvider, ProviderRef) then
        SetProvider(ProviderRef)
      else
        raise EJVCLException.Create('Component does not support the IJvDataProvider interface.');
    end
    else
      raise EJVCLException.Create('Component does not support the IInterfaceComponentReference interface.');
  end;
end;
{$ENDIF COMPILER6_UP}

function TJvDataConsumer._AddRef: Integer;
begin
  Result := -1;
end;

function TJvDataConsumer._Release: Integer;
begin
  Result := -1;
end;

procedure TJvDataConsumer.DoProviderChanging(ADataProvider: IJvDataProvider;
  AReason: TDataProviderChangeReason; Source: IUnknown);
begin
end;

procedure TJvDataConsumer.DoProviderChanged(ADataProvider: IJvDataProvider;
  AReason: TDataProviderChangeReason; Source: IUnknown);
begin
end;

procedure TJvDataConsumer.DoChanged;
begin
  if @FOnChanged <> nil then
    OnChanged(Self);
end;

procedure TJvDataConsumer.DoAddAttribute(Attr: Integer);
begin
  if not AttributeApplies(Attr) then
  begin
    SetLength(FAttrList, Length(FAttrList) + 1);
    FAttrList[High(FAttrList)] := Attr;
  end;
end;

procedure TJvDataConsumer.Changed;
begin
  if VCLComponent is TControl then
    TControl(VCLComponent).Invalidate;
  DoChanged;
end;

procedure TJvDataConsumer.ProviderChanging;
var
  I: Integer;
begin
  if FAdditionalIntfImpl <> nil then
  begin
    if not FNeedFixups then
    begin
      I := 0;
      while I < ExtensionCount do
      begin
        Extension(I).ProviderChanging;
        Inc(I);
      end
    end;
  end;
end;

procedure TJvDataConsumer.ProviderChanged;
var
  I: Integer;
begin
  if FAdditionalIntfImpl <> nil then
  begin
    if not FNeedFixups then
    begin
      I := 0;
      while I < ExtensionCount do
      begin
        if Extension(I).KeepOnProviderChange then
        begin
          Extension(I).ProviderChanged;
          Inc(I);
        end
        else
          RemoveIntfImpl(Extension(I));
      end;
    end;
    UpdateExtensions;
  end;
end;

procedure TJvDataConsumer.ContextChanging;
var
  I: Integer;
begin
  if FAdditionalIntfImpl <> nil then
  begin
    if not FNeedFixups then
    begin
      I := 0;
      while I < ExtensionCount do
      begin
        Extension(I).ContextChanging;
        Inc(I);
      end
    end;
  end;
end;

procedure TJvDataConsumer.ContextChanged;
var
  I: Integer;
begin
  if FAdditionalIntfImpl <> nil then
  begin
    if not FNeedFixups then
    begin
      I := 0;
      while I < ExtensionCount do
      begin
        if Extension(I).KeepOnContextChange then
        begin
          Extension(I).ContextChanged;
          Inc(I);
        end
        else
          RemoveIntfImpl(Extension(I));
      end;
    end;
    UpdateExtensions;
  end;
end;

procedure TJvDataConsumer.UpdateExtensions;
var
  ImplArray: TClassArray;
  I: Integer;
begin
  SetLength(ImplArray, 0);
  if ProviderIntf <> nil then
  begin
    DP_SelectConsumerContext(ProviderIntf, Self, ContextIntf);
    try
      ImplArray := ProviderIntf.ConsumerClasses;
    finally
      DP_ReleaseConsumerContext(ProviderIntf);
    end;
    for I := Low(ImplArray) to High(ImplArray) do
    begin
      if IndexOfImplClass(TAggregatedPersistentExClass(ImplArray[I])) < 0 then
        TJvDataConsumerAggregatedObjectClass(ImplArray[I]).Create(Self);
    end;
    if AttributeApplies(DPA_ConsumerDisplaysList) and (IndexOfImplClass(TJvDataConsumerViewList) < 0) then
      TJvDataConsumerViewList.Create(Self);
  end
  else
    ClearIntfImpl;
end;

procedure TJvDataConsumer.FixupExtensions;
var
  I: Integer;
begin
  for I := 0 to ExtensionCount - 1 do
    Extension(I).Fixup;
end;

procedure TJvDataConsumer.ViewChanged(AExtension: TJvDataConsumerAggregatedObject);
var
  I: Integer;
begin
  for I := 0 to ExtensionCount - 1 do
    if Extension(I) <> AExtension then
    Extension(I).ViewChanged(AExtension);
  Changed;
end;

function TJvDataConsumer.ExtensionCount: Integer;
begin
  Result := FAdditionalIntfImpl.Count;
end;

function TJvDataConsumer.Extension(Index: Integer): TJvDataConsumerAggregatedObject;
begin
  Result := TJvDataConsumerAggregatedObject(FAdditionalIntfImpl[Index]);
end;

function TJvDataConsumer.GetContext: TJvDataContextID;
begin
  if FContext = nil then
    Result := ''
  else
    Result := FContext.Name;
end;

procedure TJvDataConsumer.SetContext(Value: TJvDataContextID);
var
  ContextsIntf: IJvDataContexts;
  ContextIntf: IJvDataContext;
begin
  if not AnsiSameStr(Value, GetContext) then
  begin
    if ProviderIntf = nil then
    begin
      if csLoading in VCLComponent.ComponentState then
        FFixupContext := Value
      else
        raise EJVCLException.Create('You must specify a provider before setting the context.');
    end
    else
    begin
      if (Value <> '') then
      begin
        if Supports(ProviderIntf, IJvDataContexts, ContextsIntf) then
        begin
          ContextIntf := ContextsIntf.GetContextByName(Value);
          if ContextIntf <> nil then
            SetContextIntf(ContextIntf)
          else
            raise EJVCLException.CreateFmt('Provider has no context named "%s"', [Value]);
        end
        else
          raise EJVCLException.Create('Provider does not support contexts.');
      end
      else
        SetContextIntf(nil);
    end;
  end;
end;

procedure TJvDataConsumer.DataProviderChanging(const ADataProvider: IJvDataProvider;
  AReason: TDataProviderChangeReason; Source: IUnknown);
begin
  case AReason of
    pcrDestroy:
      Provider := nil;
    else
      DoProviderChanging(ADataProvider, AReason, Source);
  end;
end;

procedure TJvDataConsumer.DataProviderChanged(const ADataProvider: IJvDataProvider;
  AReason: TDataProviderChangeReason; Source: IUnknown);
begin
  DoProviderChanged(ADataProvider, AReason, Source);
  Changed;
end;

function TJvDataConsumer.VCLComponent: TComponent;
begin
  Result := FOwner;
end;

function TJvDataConsumer.AttributeApplies(Attr: Integer): Boolean;
var
  I: Integer;
begin
  I := High(FAttrList);
  while (I >= 0) and (FAttrList[I] <> Attr) do
    Dec(I);
  Result := I >= 0;
end;

constructor TJvDataConsumer.Create(AOwner: TComponent; Attributes: array of Integer);
var
  I: Integer;
begin
  inherited Create;
  FOwner := AOwner;
  for I := Low(Attributes) to High(Attributes) do
    DoAddAttribute(Attributes[I]);
end;

destructor TJvDataConsumer.Destroy;
begin
  FOnChanged := nil;
  Provider := nil;
  inherited Destroy;
end;

function TJvDataConsumer.ProviderIntf: IJvDataProvider;
begin
  Result := FProvider;
end;

procedure TJvDataConsumer.SetProviderIntf(Value: IJvDataProvider);
begin
  SetProvider(Value);
end;

function TJvDataConsumer.ContextIntf: IJvDataContext;
begin
  Result := FContext;
end;

procedure TJvDataConsumer.SetContextIntf(Value: IJvDataContext);
begin
  if Value <> ContextIntf then
  begin
    if (Value <> nil) and (Value.Contexts.Provider <> ProviderIntf) then
      raise EJVCLException.Create('The specified context is not part of the same provider.');
    ContextChanging;
    FContext := Value;
    ContextChanged;
    Changed;
  end;
end;

procedure TJvDataConsumer.Enter;
begin
  DP_SelectConsumerContext(ProviderIntf, Self, ContextIntf);
end;

procedure TJvDataConsumer.Leave;
begin
  DP_ReleaseConsumerContext(ProviderIntf);
end;

{ TJvDataConsumerAggregatedObject }

procedure TJvDataConsumerAggregatedObject.Fixup;
begin
end;

function TJvDataConsumerAggregatedObject.KeepOnProviderChange: Boolean;
begin
  Result := False;
end;

function TJvDataConsumerAggregatedObject.KeepOnContextChange: Boolean;
begin
  Result := True;
end;

procedure TJvDataConsumerAggregatedObject.Changed;
begin
  ConsumerImpl.Changed;
end;

procedure TJvDataConsumerAggregatedObject.NotifyViewChanged;
begin
  ConsumerImpl.ViewChanged(Self);
end;

procedure TJvDataConsumerAggregatedObject.ViewChanged(AExtension: TJvDataConsumerAggregatedObject);
begin
end;

procedure TJvDataConsumerAggregatedObject.NotifyFixups;
begin
  ConsumerImpl.FNeedFixups := True;
end;

procedure TJvDataConsumerAggregatedObject.ProviderChanging;
begin
end;

procedure TJvDataConsumerAggregatedObject.ProviderChanged;
begin
end;

procedure TJvDataConsumerAggregatedObject.ContextChanging;
begin
end;

procedure TJvDataConsumerAggregatedObject.ContextChanged;
begin
end;

function TJvDataConsumerAggregatedObject.Consumer: IJvDataConsumer;
begin
  Result := Owner as IJvDataConsumer;
end;

function TJvDataConsumerAggregatedObject.ConsumerImpl: TJvDataConsumer;
begin
  Result := Owner as TJvDataConsumer;
end;

function TJvDataConsumerAggregatedObject.RootItems: IJvDataItems;
var
  RootSelect: IJvDataConsumerItemSelect;
begin
try
  if Supports(Consumer, IJvDataConsumerItemSelect, RootSelect) and (RootSelect.GetItem <> nil) then
    RootSelect.GetItem.QueryInterface(IJvDataItems, Result)
  else
    ConsumerImpl.ProviderIntf.QueryInterface(IJvDataItems, Result);
finally
  {$IFDEF DEBUG}
  if Result = nil then
    DBugIntf.SendDebugEx('RootItems returns nil!', mtError);
  {$ENDIF DEBUG}
end;
end;

//===TJvDataConsumerContext=========================================================================

function TJvDataConsumerContext.GetContext: IJvDataContext;
begin
  Result := ConsumerImpl.ContextIntf;
end;

procedure TJvDataConsumerContext.SetContext(Value: IJvDataContext);
begin
  ConsumerImpl.SetContextIntf(Value);
end;

//===TJvDataConsumerItemSelect======================================================================

procedure TJvDataConsumerItemSelect.Fixup;
begin
  SetItem(FItemID);
  FItemID := '';
end;

function TJvDataConsumerItemSelect.GetItem: TJvDataItemID;
begin
  if GetItemIntf = nil then
    Result := ''
  else
    Result := GetItemIntf.GetID;
end;

procedure TJvDataConsumerItemSelect.SetItem(Value: TJvDataItemID);
var
  TmpItem: IJvDataItem;
begin
  if not AnsiSameStr(Value, GetItem) then
  begin
    if Value = '' then
      SetItemIntf(nil)
    else
    begin
      if (ConsumerImpl.ProviderIntf = nil) then
      begin
        if csLoading in Consumer.VCLComponent.ComponentState then
        begin
          FItemID := Value;
          NotifyFixups;
          Exit;
        end
        else
          raise EJVCLException.Create('You must specify a provider before setting the item.');
      end
      else
      begin
        ConsumerImpl.Enter;
        try
          TmpItem := (ConsumerImpl.ProviderIntf as IJvDataIDSearch).Find(Value, True);
          if TmpItem <> nil then
            SetItemIntf(TmpItem)
          else
            raise EJVCLException.Create('Item not found in the selected context.');
        finally
          ConsumerImpl.Leave;
        end;
      end;
    end;
  end;
end;

function TJvDataConsumerItemSelect.GetItemIntf: IJvDataItem;
begin
  Result := FItem;
end;

procedure TJvDataConsumerItemSelect.SetItemIntf(Value: IJvDataItem);
begin
  if Value <> GetItemIntf then
  begin
    FItem := Value;
    NotifyViewChanged;
    Changed;
  end;
end;

//===TJvCustomDataConsumerViewList==================================================================

function TJvCustomDataConsumerViewList.KeepOnProviderChange: Boolean;
begin
  Result := True;
end;

procedure TJvCustomDataConsumerViewList.ProviderChanging;
begin
  if ConsumerImpl.ProviderIntf <> nil then
    ConsumerImpl.ProviderIntf.UnregisterChangeNotify(FNotifier);
  ClearView;
end;

procedure TJvCustomDataConsumerViewList.ProviderChanged;
begin
  if ConsumerImpl.ProviderIntf <> nil then
    ConsumerImpl.ProviderIntf.RegisterChangeNotify(FNotifier);
//  RebuildView;
end;

procedure TJvCustomDataConsumerViewList.ContextChanged;
begin
//  RebuildView;
end;

procedure TJvCustomDataConsumerViewList.ViewChanged(AExtension: TJvDataConsumerAggregatedObject);
begin
//  RebuildView;
end;

procedure TJvCustomDataConsumerViewList.DataProviderChanging(ADataProvider: IJvDataProvider;
  AReason: TDataProviderChangeReason; Source: IUnknown);
var
  ItemIdx: Integer;
begin
  case AReason of
    pcrDelete:
      begin
        // Source is a reference to the item being deleted
        if (Source <> nil) then
        begin
          ItemIdx := IndexOfItem(IJvDataItem(Source));
          if ItemIdx >= 0 then
            DeleteItem(ItemIdx);
        end;
      end;
  end;
end;

procedure TJvCustomDataConsumerViewList.DataProviderChanged(ADataProvider: IJvDataProvider;
  AReason: TDataProviderChangeReason; Source: IUnknown);
var
  ParItem: IJvDataItem;
  ParIdx: Integer;
begin
  case AReason of
    pcrAdd:
      begin
        // Source is a reference to the new item
        if (Source <> nil) then
        begin
          ParItem := IJvDataItem(Source).GetItems.GetParent;
          if ParItem <> nil then
          begin
            ParIdx := IndexOfItem(ParItem);
            if (ParIdx < 0) and ExpandOnNewItem then
            begin
              // Make sure the tree is expanded up to the parent item
              ExpandTreeTo(ParItem);
              ParIdx := IndexOfItem(ParItem);
            end;
            if ParIdx >= 0 then
            begin
              if not ItemIsExpanded(ParIdx) and ExpandOnNewItem then
                // Expand parent item; will retrieve all sub items, including the newly added item
                ToggleItem(ParIdx)
              else if ItemIsExpanded(ParIdx) then
                // parent is expanded, add the new item to the view.
                AddChildItem(ParIdx, IJvDataItem(Source));
            end;
          end
          else
            // Item at the root; always add it
            AddChildItem(-1, IJvDataItem(Source));
        end;
      end;
  end;
end;

function TJvCustomDataConsumerViewList.InternalItemSibling(ParentIndex: Integer;
  var ScanIndex: Integer): Integer;
var
  Lvl: Integer;
begin
  Lvl := ItemLevel(ParentIndex);
  if ScanIndex <= ParentIndex then
    ScanIndex := ParentIndex + 1;
  while (ScanIndex < Count) and (ItemLevel(ScanIndex) > Lvl) do
    Inc(ScanIndex);
  if (ScanIndex >= Count) or (ItemLevel(ScanIndex) < Lvl) then
    Result := -1
  else
    Result := ScanIndex;
  if ScanIndex > Count then
    ScanIndex := Count;
end;

function TJvCustomDataConsumerViewList.Get_AutoExpandLevel: Integer;
begin
  Result := FAutoExpandLevel;
end;

procedure TJvCustomDataConsumerViewList.Set_AutoExpandLevel(Value: Integer);
begin
  FAutoExpandLevel := Value;
end;

function TJvCustomDataConsumerViewList.Get_ExpandOnNewItem: Boolean;
begin
  Result := FExpandOnNewItem;
end;

procedure TJvCustomDataConsumerViewList.Set_ExpandOnNewItem(Value: Boolean);
begin
  FExpandOnNewItem := Value;
end;

procedure TJvCustomDataConsumerViewList.ClearView;
begin
  // override if the implementation can be optimized
  while Count > 0 do
    DeleteItem(0);
end;

procedure TJvCustomDataConsumerViewList.RebuildView;
var
  Idx: Integer;
begin
  {$IFDEF DEBUG}
  DBugIntf.SendMethodEnter('TJvCustomDataConsumerViewList.RebuildView');
  {$ENDIF DEBUG}
  ClearView;
  {$IFDEF DEBUG}
    DBugIntf.SendDebug('View has been cleared.');
  {$ENDIF DEBUG}
  if (ConsumerImpl <> nil) and (ConsumerImpl.ProviderIntf <> nil) then
  begin
    Idx := 0;
  {$IFDEF DEBUG}
    DBugIntf.SendDebug('Calling AddItems...');
  {$ENDIF DEBUG}
    AddItems(Idx, RootItems, AutoExpandLevel);
  end;
  {$IFDEF DEBUG}
  DBugIntf.SendMethodExit('TJvCustomDataConsumerViewList.RebuildView');
  {$ENDIF DEBUG}
end;

constructor TJvCustomDataConsumerViewList.Create(AOwner: TExtensibleInterfacedPersistent);
begin
  inherited Create(AOwner);
  FNotifier := TJvProviderNotification.Create;
  if ConsumerImpl.ProviderIntf <> nil then
    COnsumerImpl.ProviderIntf.RegisterChangeNotify(FNotifier);
end;

destructor TJvCustomDataConsumerViewList.Destroy;
begin
  if FNotifier <> nil then
  begin
    if (ConsumerImpl <> nil) and (ConsumerImpl.ProviderIntf <> nil) then
      COnsumerImpl.ProviderIntf.UnregisterChangeNotify(FNotifier);
    FreeAndNil(FNotifier);
  end;
  inherited Destroy;
end;

procedure TJvCustomDataConsumerViewList.ExpandTreeTo(Item: IJvDataItem);
var
  ParIdx: Integer;
begin
  if IndexOfID(Item.GetID) < 0 then
  begin
    ExpandTreeTo(Item.Items.GetParent);
    ParIdx := IndexOfID(Item.Items.GetParent.GetID);
    if ItemIsExpanded(ParIdx) then // we have a big problem <g>
      raise EJVCLException.Create('ViewList out of sync');
    ToggleItem(ParIdx);
  end;
end;

procedure SetBit(var IntArray: array of Integer; BitNo: Integer);
var
  ArrayOffset: Integer;
  BitOffset: Integer;
begin
  ArrayOffset := BitNo div 32;
  BitOffset := BitNo mod 32;
  IntArray[ArrayOffset] := IntArray[ArrayOffset] or (1 shl BitOffset);
end;

function TJvCustomDataConsumerViewList.ItemGroupInfo(Index: Integer): TDynIntegerArray;
var
  LvlIdx: Integer;
  LastScanIndex: Integer;
begin
  LvlIdx := ItemLevel(Index) - 1;
  SetLength(Result, LvlIdx div 32 + LvlIdx mod 32);
  LastScanIndex := Index;
  { Keep using the last scanned item as a start point to find a sibling for the next parent. Reduces
    the number of compares to make. }
  while LvlIdx >= 0 do
  begin
    Index := ItemParentIndex(Index);
    if InternalItemSibling(Index, LastScanIndex) <> -1 then
      SetBit(Result, LvlIdx); // There's another sibling at this level; set the corresponding bit
    Dec(LvlIdx);
  end;
end;

//===TJvDataConsumerViewList========================================================================

procedure TJvDataConsumerViewList.AddItem(Index: Integer; Item: IJvDataItem; ExpandToLevel: Integer);
var
  Lvl: Integer;
  Idx: Integer;
  SubItems: IJvDataItems;
begin
  if Index < 0 then
  begin
    Lvl := 0;
    Idx := Count;
  end
  else
  begin
    Lvl := Succ(ItemLevel(Index));
    Idx := Index + 1;
    if FViewItems[Index].Flags and (vifHasChildren + vifExpanded) = vifHasChildren then
    begin
      ToggleItem(Index);
      Exit;
    end;
  end;
  while (Idx < Count) and (ItemLevel(Idx) >= Lvl) do
    Inc(Idx);
  SetLength(FViewItems, Length(FViewItems) + 1);
  if Idx < High(FViewItems) then
  begin
    Move(FViewItems[Idx], FViewItems[Idx + 1], (High(FViewItems) - Idx) * SizeOf(FViewItems[0]));
    FillChar(FViewItems[Idx], SizeOf(FViewItems[0]), 0);
  end;
  with FViewItems[Idx] do
  begin
    ItemID := Item.GetID;
    if Supports(Item, IJvDataItems, SubItems) then
    begin
      if SubItems.Count > 0 then
        Flags := Lvl + vifHasChildren + vifCanHaveChildren
      else
        Flags := Lvl + vifCanHaveChildren
    end
    else
      Flags := Lvl;
  end;
  if Index > -1 then
    with FViewItems[Index] do
      Flags := Flags or vifHasChildren or vifCanHaveChildren or vifExpanded;
  if (ExpandToLevel <> 0) and (SubItems <> nil) and (SubItems.Count > 0) then
  begin
    Inc(Index);
    AddItems(Index, SubItems, ExpandToLevel - 1);
  end;
end;

procedure TJvDataConsumerViewList.AddChildItem(ParentIndex: Integer; Item: IJvDataItem);
var
  InsertIndex: Integer;
begin
  if ParentIndex > -1 then
  begin
    if not ItemIsExpanded(ParentIndex) then
      ToggleItem(ParentIndex);
    if IndexOfItem(Item) < 0 then
    begin
      InternalItemSibling(ParentIndex, InsertIndex);
    end;
  end
  else
    InsertIndex := Count;
  InsertItem(ParentIndex, InsertIndex, Item);
end;

procedure TJvDataConsumerViewList.AddItems(var Index: Integer; Items: IJvDataItems; ExpandToLevel: Integer);
var
  I: Integer;
  J: Integer;
  SubItems: IJvDataItems;
begin
  J := Count;
  SetLength(FViewItems, Count + Items.Count);
  if Index < J then
  begin
    Move(FViewItems[Index], FViewItems[Index + Items.Count], (J - Index) * SizeOf(FViewItems[0]));
    FillChar(FViewItems[Index], Items.Count * SizeOf(FViewItems[0]), 0);
  end;
  J := 0;
  if Index > 0 then
  begin
    J := 1 + FViewItems[Index - 1].Flags and $00FFFFFF;
    FViewItems[Index - 1].Flags := FViewItems[Index - 1].Flags or vifExpanded;
  end;
  for I  := 0 to Items.Count - 1 do
  begin
    with FViewItems[Index] do
    begin
      ItemID := Items.Items[I].GetID;
      Flags := J;
      if Supports(Items.Items[I], IJvDataItems, SubItems) then
      begin
        Flags := Flags + vifCanHaveChildren;
        if SubItems.Count > 0 then
        begin
          Flags := Flags + vifHasChildren;
          if ExpandToLevel <> 0 then
          begin
            Inc(Index);
            AddItems(Index, SubItems, ExpandToLevel - 1);
            Dec(Index);
          end;
        end;
      end;
    end;
    Inc(Index);
  end;
end;

procedure TJvDataConsumerViewList.InsertItem(InsertIndex, ParentIndex: Integer; Item: IJvDataItem);
var
  Level: Integer;
  SubItems: IJvDataItems;
begin
  if ParentIndex < 0 then
    Level := 0
  else
    Level := Succ(ItemLevel(ParentIndex));
  SetLength(FViewItems, Count + 1);
  if InsertIndex < High(FViewItems) then
  begin
    Move(FViewItems[InsertIndex], FViewItems[InsertIndex + 1], (High(FViewItems) - InsertIndex) * SizeOf(FViewItems[0]));
    FillChar(FViewItems[InsertIndex], SizeOf(FViewItems[0]), 0);
  end;
  with FViewItems[InsertIndex] do
  begin
    ItemID := Item.GetID;
    if Supports(Item, IJvDataItems, SubItems) then
    begin
      Level := Level + vifCanHaveChildren;
      if SubItems.Count > 0 then
        Level := Level + vifHasChildren;
    end;
    Flags := Level;
  end;
  if ParentIndex >= 0 then
    FViewItems[ParentIndex].Flags := FViewItems[ParentIndex].Flags or (vifCanHaveChildren +
      vifHasChildren + vifExpanded);
end;

procedure TJvDataConsumerViewList.DeleteItem(Index: Integer);
var
  PrevIsParent: Boolean;
begin
  DeleteItems(Index);
  PrevIsParent := (Index > 0) and (ItemLevel(Index - 1) = (Itemlevel(Index) - 1));
  FViewItems[Index].ItemID := '';
  if Index < High(FViewItems) then
    Move(FViewItems[Index + 1], FViewItems[Index], (Length(FViewItems) - Index) * SizeOf(FViewItems[0]));
  FillChar(FViewItems[High(FViewItems)], SizeOf(FViewItems[0]), 0);
  SetLength(FViewItems, High(FViewItems));
  if PrevIsParent and ((Index = High(FViewItems)) or (ItemLevel(Index - 1) <> (ItemLevel(Index) - 1))) then
    FViewItems[Index - 1].Flags := FViewItems[Index - 1].Flags and not (vifHasChildren or vifExpanded);
end;

procedure TJvDataConsumerViewList.DeleteItems(Index: Integer);
var
  Idx: Integer;
  Lvl: Integer;
begin
  if FViewItems[Index].Flags and (vifExpanded + vifHasChildren) = (vifExpanded + vifHasChildren) then
  begin
    Lvl := ItemLevel(Index) + 1;
    Idx := Index + 1;
    while (Idx < Length(FViewItems)) and (ItemLevel(Idx) >= Lvl) do
    begin
      FViewItems[Idx].ItemID := '';
      Inc(Idx);
    end;
    // Idx points to next item that is not a child
    if Idx < Count then
      Move(FViewItems[Idx], FViewItems[Index + 1], (Length(FViewItems) - Idx) * SizeOf(FViewItems[0]));
    FillChar(FViewItems[Length(FViewItems) - Pred(Idx - Index)], Pred(Idx - Index) * SizeOf(FViewItems[0]), 0);
    SetLength(FViewItems, Length(FViewItems) - (Idx - Index - 1));
    FViewItems[Index].Flags := FViewItems[Index].Flags and not vifExpanded;
  end;
end;

procedure TJvDataConsumerViewList.ToggleItem(Index: Integer);
var
  TmpItem: IJvDataItem;
  Items: IJvDataItems;
begin
  if ItemHasChildren(Index) then
  begin
    if ItemIsExpanded(Index) then
      DeleteItems(Index)
    else
    begin
      TmpItem := Item(Index);
      if (TmpItem <> nil) and Supports(TmpItem, IJvDataItems, Items) then
      begin
        Inc(Index);
        AddItems(Index, Items);
      end;
    end;
    NotifyViewChanged;
  end;
end;

function TJvDataConsumerViewList.IndexOfItem(Item: IJvDataItem): Integer;
begin
  Result := IndexOfID(Item.GetID);
end;

function TJvDataConsumerViewList.IndexOfID(ID: TJvDataItemID): Integer;
begin
  Result := Count - 1;
  while (Result >= 0) and not AnsiSameText(FViewItems[Result].ItemID, ID) do
    Dec(Result);
end;

function TJvDataConsumerViewList.ChildIndexOfItem(Item: IJvDataItem): Integer;
begin
  Result := ChildIndexOfID(Item.GetID);
end;

function TJvDataConsumerViewList.ChildIndexOfID(ID: TJvDataItemID): Integer;
var
  Index: Integer;
  ChildLevel: Integer;
begin
  Result := -1;
  Index := IndexOfID(ID);
  if Index >= 0 then
  begin
    Inc(Result);
    if Index > 0 then
    begin
      ChildLevel := ItemLevel(Index);
      Dec(Index);
      while (Index >= 0) and (ItemLevel(Index) >= ChildLevel) do
      begin
        if ItemLevel(Index) = ChildLevel then
          Inc(Result);
        Dec(Index);
      end;
    end;
  end;
end;

function TJvDataConsumerViewList.Item(Index: Integer): IJvDataItem;
var
  Items: IJvDataItems;
  {$IFDEF ViewList_UseFinder}
  Finder: IJvDataIDSearch;
  {$ELSE}
  ItemIdx: Integer;
  ParIdx: Integer;
  {$ENDIF ViewList_UseFinder}
begin
  {$IFDEF ViewList_UseFinder}
  { The easiest way: use IJvDataIDSearch to locate the item given it's ID value. Scans all items
    recursively until it finds a match or nothing at all. Could be rather slow on larger trees. }
  Items := RootItems;
  if Supports(RootItems, IJvDataIDSearch, Finder) then
    Result := Finder.Find(FViewItems[Index].ItemID, True);
  {$ELSE}
  { This should be faster, especially with larger trees. Determine the child index, retrieve the
    parent item (using this same method) and then get the specified sub item directly.
    Saves a huge number of ID comparisons and for dynamic items also an enormous amount of
    creation/destruction of items. }
  ItemIdx := ChildIndexOfID(FViewItems[Index].ItemID);
  ParIdx := ItemParentIndex(Index);
  if ParIdx >= 0 then
    // Parent found, retrieve the IJVDataItems reference
    Item(ParIdx).QueryInterface(IJvDataItems, Items)
  else
    // Apparantly this item is at the root of the view; retrieve the proper IJvDataItems reference
    Items := RootItems;
  // Retrieve the child item.
  Result := Items.GetItem(ItemIdx);
  {$ENDIF ViewList_UseFinder}
end;

function TJvDataConsumerViewList.ItemLevel(Index: Integer): Integer;
begin
  Result := FViewItems[Index].Flags and $00FFFFFF;
end;

function TJvDataConsumerViewList.ItemIsExpanded(Index: Integer): Boolean;
begin
  Result := FViewItems[Index].Flags and vifExpanded <> 0;
end;

function TJvDataConsumerViewList.ItemHasChildren(Index: Integer): Boolean;
begin
  Result := FViewItems[Index].Flags and vifHasChildren <> 0;
end;

function TJvDataConsumerViewList.ItemParent(Index: Integer): IJvDataItem;
begin
end;

function TJvDataConsumerViewList.ItemParentIndex(Index: Integer): Integer;
var
  ParLevel: Integer;
begin
  ParLevel := ItemLevel(Index) - 1;
  Result := Index - 1;
  while (Result >= 0) and (ItemLevel(Result) > ParLevel) do
    Dec(Result);
end;

function TJvDataConsumerViewList.ItemSibling(Index: Integer): IJvDataItem;
var
  Idx: Integer;
begin
  Idx := ItemSiblingIndex(Index);
  if Idx > -1 then
    Result := Item(Idx)
  else
    Result := nil;
end;

function TJvDataConsumerViewList.ItemSiblingIndex(Index: Integer): Integer;
begin
  Result := InternalItemSibling(Index, Index);
end;

function TJvDataConsumerViewList.SubItem(Parent: IJvDataItem; Index: Integer): IJvDataItem;
begin
  Result := SubItem(IndexOfItem(Parent), Index);
end;

function TJvDataConsumerViewList.SubItem(Parent, Index: Integer): IJvDataItem;
var
  Idx: Integer;
begin
  Idx := SubItemIndex(Parent, Index);
  if Idx > -1 then
    Result := Item(Idx)
  else
    Result := nil;
end;

function TJvDataConsumerViewList.SubItemIndex(Parent: IJvDataItem; Index: Integer): Integer;
begin
  Result := SubItemIndex(IndexOfItem(Parent), Index);
end;

function TJvDataConsumerViewList.SubItemIndex(Parent, Index: Integer): Integer;
begin
  Result := Parent + 1;
  while (Result >= 0) and (Index >= 0) do
  begin
    Dec(Index);
    if Index >= 0 then
      Result := ItemSiblingIndex(Result);
  end;
end;

function TJvDataConsumerViewList.Count: Integer;
begin
  Result := Length(FViewItems);
end;

initialization
  RegisterClasses([TJvBaseDataItem, TJvCustomDataItemsTextRenderer, TJvDataItemTextImpl,
    TJvDataItemImageImpl, TJvDataItemsList, TJvBaseDataItemsListManagement,
    TJvCustomDataItemsImages, TJvDataConsumer, TJvDataConsumerItemSelect]);
end.
