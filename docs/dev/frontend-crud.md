# Frontend CRUD

**IXP Manager**, like many applications, has a lot of tables that need basic CRUD access: **CR**eate, **U**pdate and **D**elete (plus list and view). In older versions of **IXP Manager** (and as yet unupdated code), we used [this Zend Framework trait](https://github.com/opensolutions/OSS-Framework/wiki/Doctrine2-Frontend) to allow us to repidly deploy CRUD interfaces.

For **IXP Manager** >= v4.7, we have duplicated (and improved) this to create a scaffolding framework in Laravel. This page documents that class.

## Configuration

In any controller using extending the `Doctrine2Frontend` class, a `_feInit()` method is required which configures the controller and, for example, allows you to set what is displayed for different levels of user privileges.

The primary purpose of this function is to define the anonymous object `_feParams` (using an object ensures that the view gets a reference to the object and not a copy of a static array at a point in time):

```php
<?php
protected function _feInit()
{
    $this->view->feParams = $this->_feParams = (object)[

        // the ORM entity object that CRUD operations will affect:
        'entity'            => InfrastructureEntity::class,  

        'pagetitle'         => 'Infrastructures',     

        // default is false. If true, add / edit / delete will be disabled
        'readonly'          => false,

        'titleSingular'     => 'Infrastructure',   
        'nameSingular'      => 'an infrastructure',   

        'defaultAction'     => 'list',
        'defaultController' => 'InfrastructureController',

        'viewFolderName'    => 'infrastructure',

        'listColumns' => [                    
            // what columns to display in the list view
            'id'         => [ 'title' => 'DB ID', 'display' => true ],
            'name'       => 'Name',
            'shortname'  => 'Shortname'
        ],

        'listOrderBy'    => 'name',    // how to order columns
        'listOrderByDir' => 'ASC',     // direction of order columns
    ];

    // you can then override some of the above for different user privileges (for example)
    switch( Auth::user() ? Auth::user()->getPrivs() : UserEntity::AUTH_PUBLIC ) {

        case UserEntity::AUTH_SUPERUSER:
            $this->_feParams->pagetitle = 'Infrastructures (Superuser View)';

            $this->_feParams->listColumns = array_merge(
                $this->_feParams->listColumns, [
                    // ...
                ];
            );
            break;

        default:
            if( php_sapi_name() !== "cli" ) {
                abort( 'error/insufficient-permissions' );
            }
    }

    // display the same information in the single object view as the list of objects
    $this->_feParams->viewColumns = $this->_feParams->listColumns;
}
```

### Access Privileges

By default, all `Doctrine2Frontend` controllers can only be accessed by an authenticated super user (`Entities\User::AUTH_SUPERUSER`). You can change this by setting the following property on your implementation:

```php
<?php
/**
 * The minimum privileges required to access this controller.
 *
 * If you set this to less than the superuser, you need to manage privileges and access
 * within your own implementation yourself.
 *
 * @var int
 */
public static $minimum_privilege = UserEntity::AUTH_SUPERUSER;
```

If you set this to less than the superuser, you need to manage privileges and access within your own implementation yourself.




### Routing

Routes are explicitly defined in Laravel. The `Doctrine2Frontend` class sets up the standard routes automatically once you add the following to your `routes/web.php` (or as appropriate) file on a per implementation basis. E.g. for the *Infrastructure* implementation, we add to `routes/web-doctrine2frontend.php`:

```php
<?php
IXP\Http\Controllers\InfrastructureController::routes();
```

Note that by placing the above in `routes/web-doctrine2frontend.php`, you ensure the appropriate middleware is attached.

This `routes()` function determines the route prefix using kebab case of the controller name. That is to say: if the controller is `CustKitController`, the determined prefix is `cust-kit`. You can override this by setting a `$route_prefix` class constant in your implementation.

The standard routes added (using `infrastructure` as an example) are:

* GET `infrastructure/add`
* GET `infrastructure/edit/{id}`
* GET `infrastructure/list`
* GET `infrastructure/view/{id}`
* POST `infrastructure/delete/{id}`
* POST `infrastructure/store`

If you want to create your own additional routes, create a function as follows in your implementation:

```php
<?php
public static function additionalRoutes( $route_prefix ) {}
```

And add routes (using the normal `Route::get()` / `::post()` / etc Laravel methods).

If you want to completely change the routes, just override the `public static function routes() {}` function.

### View Templates

All the common view templates for thss functionality can be found in `resources/views/frontend` directory. You can override any of these with your own by creating a template of the same name and placing it under `resources/views/xxx` (or `resources/skins/skinname/xxx`) where `xxx` is the `feParams['viewFolderName']`.


## Actions

Each of the typical CRUD actions will be described here.

**NB: the best documentation is sometimes the code. Check out the above routes file (`routes/web-doctrine2frontend.php`) and examine some of the implemented controllers directly.**

### List

The list action is for listing the contents of a database table in a HTML / DataTables view.

The only requirement of the list action is that the following abstract function is implemented:

```php
<?php
/**
 * Provide array of table rows for the list action (and view action)
 *
 * @param int $id The `id` of the row to load for `view` action. `null` if `list` action.
 * @return array
 */
abstract protected function listGetData( $id = null );
```

A sample implementation for the infrastructure controller just calls a Doctrine2 repository function:

```php
<?php
protected function listGetData( $id = null ) {
    return D2EM::getRepository( InfrastructureEntity::class )->getAllForFeList( $this->feParams, $id );
}
```

The table rows returned in the above array must be associatative arrays with keys matching the `feParams['listColumns']` definition.

The list view template optionally includes other templates you can define (where `xxx` below is the `feParams['viewFolderName']`):

1. the list view includes a JavaScript template `resources/views/frontend/js/list` which activates the DataTables, sets up sorting, etc. You can override this (and include the original if appropriate) if you want to add additional JS functionality.
2. if the `resources/views/xxx/list-preamble` template exists, it is included just before the table.
3. if the `resources/views/xxx/list-postamble` template exists, it is included just after the table.

### View

The view action is for showing a single database row identified by the id passed in the URL.

The only requirement of the view action is that the abstract function `listGetData( $id = null )` as used by the list action has been correctly implemented to take an optional ID and return an array with a single element matching that ID.

The table rows returned in the above array must be associatative arrays with keys matching the `feParams['viewColumns']` definition.

The list view template optionally includes other templates you can define (where `xxx` below is the `feParams['viewFolderName']`):

1. an optional JavaScript template `resources/views/frontend/js/view`.
2. if the `resources/views/xxx/view-preamble` template exists, it is included just before the view panel.
3. if the `resources/views/xxx/view-postamble` template exists, it is included just after the view panel.


### Create / Update Form

The presentation of the create / update (also known as add / edit) page is discussed here. Form processing and storage will be dealt with in the next section.

The first required element of this functionality is the implementation of the following abstract function:

```php
<?php
abstract protected function addEditPrepareForm( $id = null ): array;
```

The use of this function is best explained with reference to an implementation from the infrastructure controller:

```php
<?php
/**
 * Display the form to add/edit an object
 * @param   int $id ID of the row to edit
 * @return array
 */
protected function addEditPrepareForm( $id = null ): array {

    $inf = false;

    if( $id !== null ) {

        if( !( $inf = D2EM::getRepository( InfrastructureEntity::class )->find( $id) ) ) {
            abort(404);
        }

        Former::populate([
            'name'             => $inf->getName(),
            'shortname'        => $inf->getShortname(),
            'isPrimary'        => $inf->getIsPrimary() ?? false,
        ]);
    }

    return [
        'inf'          => $inf
    ];
}
```

Note from the above:

* this function operates for add and edit. In the case of edit, it tries to load the appropriate object from the database.
* if it's an edit operation, the [Former](https://github.com/formers/former) object is built up containing the existing objects details.
* you can pass back any data you wish in the returned array and it will be available via `$t->params` in the template. Note that `$t->params['data']` is added later and contains the feParams object.

The next required element is building the actual [Former](https://github.com/formers/former) object for display. For this, you must create a custom `resources/views/xxx/edit-form` template. See, as an example, the infrastructure one under `resources/views/infrastructure/edit-form.js`.

The add/edit view template optionally includes other templates you can define (where `xxx` below is the `feParams['viewFolderName']`):

1. an optional JavaScript template `resources/views/xxx/js/edit`.
2. if the `resources/views/xxx/edit-preamble` template exists, it is included just before the view panel.
3. if the `resources/views/xxx/edit-postamble` template exists, it is included just after the view panel.

You can query the boolean `$t->params['isAdd']` in your templates to distinguish between add and edit operations.

### Create / Update Store

Storing the edited / new object requires implementing a single abstract method which manages validation and storage. This is best explained with a practical implementation:

```php
<?php
/**
 * Function to do the actual validation and storing of the submitted object.
 * @param Request $request
 * @return bool|RedirectResponse
 */
public function doStore( Request $request )
{
    $validator = Validator::make( $request->all(), [
        'name'                  => 'required|string|max:255',
        'shortname'             => 'required|string|max:255',
    ]);

    if( $validator->fails() ) {
        return Redirect::back()->withErrors($validator)->withInput();
    }

    if( $request->input( 'id', false ) ) {
        if( !( $inf = D2EM::getRepository( InfrastructureEntity::class )->find( $request->input( 'id' ) ) ) ) {
            abort(404);
        }
    } else {
        $inf = new InfrastructureEntity;
        D2EM::persist( $inf );
    }

    $inf->setName(              $request->input( 'name'         ) );
    $inf->setShortname(         $request->input( 'shortname'    ) );
    $inf->setIxfIxId(           $request->input( 'ixf_ix_id'    ) ? $request->input( 'ixf_ix_id'    ) : null );
    $inf->setPeeringdbIxId(     $request->input( 'pdb_ixp'      ) ? $request->input( 'pdb_ixp'      ) : null );
    $inf->setIsPrimary(         $request->input( 'primary'      ) ?? false );
    $inf->setIXP(               D2EM::getRepository( IXPEntity::class )->getDefault() );

    D2EM::flush($inf);

    if( $inf->getIsPrimary() ) {
        // reset the rest:
        foreach( D2EM::getRepository( InfrastructureEntity::class )->findAll() as $i ) {
            if( $i->getId() == $inf->getId() || !$i->getIsPrimary() ) {
                continue;
            }
            $i->setIsPrimary( false );
        }
        D2EM::flush();
    }

    $this->object = $inf;
    return true;
}
```

Note from this:

* validation is the standard [Laravel validation](https://laravel.com/docs/5.5/validation) which works well with [Former](https://github.com/formers/former).
* it's important to remember to assign the object as: `$this->object = $inf;` as it is used to create log messages, etc.





















x

x

x

x

x


x
