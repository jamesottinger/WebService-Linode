package WebService::Linode;

require 5.006000;

use warnings;
use strict;

use Carp;
use List::Util qw(first);
use WebService::Linode::Base;

our $VERSION = '0.28';
our @ISA     = ("WebService::Linode::Base");
our $AUTOLOAD;

# beginvalidation
my $validation = {
    account => {
        estimateinvoice => [ [ 'mode' ], [qw( linodeid paymentterm planid )] ],
        info => [ [], [] ],
        paybalance => [ [], [] ],
        updatecard => [ [qw( ccexpmonth ccexpyear ccnumber )], [] ],
    },
    api => {
        spec => [ [], [] ],
    },
    avail => {
        datacenters => [ [], [] ],
        distributions => [ [], [ 'distributionid' ] ],
        kernels => [ [], [ 'isxen', 'kernelid' ] ],
        linodeplans => [ [], [ 'planid' ] ],
        nodebalancers => [ [], [] ],
        stackscripts => [ [], [qw( distributionid distributionvendor keywords )] ],
    },
    domain => {
        create => [ [ 'domain', 'type' ], [qw( axfr_ips description expire_sec lpm_displaygroup master_ips refresh_sec retry_sec soa_email status ttl_sec )] ],
        delete => [ [ 'domainid' ], [] ],
        list => [ [], [ 'domainid' ] ],
        update => [ [ 'domainid' ], [qw( axfr_ips description domain expire_sec lpm_displaygroup master_ips refresh_sec retry_sec soa_email status ttl_sec type )] ],
    },
    domain_resource => {
        create => [ [ 'domainid', 'type' ], [qw( name port priority protocol target ttl_sec weight )] ],
        delete => [ [ 'domainid', 'resourceid' ], [] ],
        list => [ [ 'domainid' ], [ 'resourceid' ] ],
        update => [ [ 'resourceid' ], [qw( domainid name port priority protocol target ttl_sec weight )] ],
    },
    image => {
        delete => [ [ 'imageid' ], [] ],
        list => [ [], [ 'imageid', 'pending' ] ],
        update => [ [ 'imageid' ], [ 'description', 'label' ] ],
    },
    linode => {
        boot => [ [ 'linodeid' ], [ 'configid' ] ],
        clone => [ [qw( datacenterid linodeid planid )], [ 'hypervisor', 'paymentterm' ] ],
        create => [ [ 'datacenterid', 'planid' ], [ 'paymentterm' ] ],
        delete => [ [ 'linodeid' ], [ 'skipchecks' ] ],
        list => [ [], [ 'linodeid' ] ],
        mutate => [ [ 'linodeid' ], [] ],
        reboot => [ [ 'linodeid' ], [ 'configid' ] ],
        resize => [ [ 'linodeid', 'planid' ], [] ],
        shutdown => [ [ 'linodeid' ], [] ],
        update => [ [ 'linodeid' ], [qw( alert_bwin_enabled alert_bwin_threshold alert_bwout_enabled alert_bwout_threshold alert_bwquota_enabled alert_bwquota_threshold alert_cpu_enabled alert_cpu_threshold alert_diskio_enabled alert_diskio_threshold backupweeklyday backupwindow label lpm_displaygroup ms_ssh_disabled ms_ssh_ip ms_ssh_port ms_ssh_user watchdog )] ],
        webconsoletoken => [ [ 'linodeid' ], [] ],
    },
    linode_config => {
        create => [ [qw( disklist kernelid label linodeid )], [qw( comments devtmpfs_automount helper_depmod helper_disableupdatedb helper_distro helper_network helper_xen ramlimit rootdevicecustom rootdevicenum rootdevicero runlevel virt_mode )] ],
        delete => [ [ 'configid', 'linodeid' ], [] ],
        list => [ [ 'linodeid' ], [ 'configid' ] ],
        update => [ [ 'configid' ], [qw( comments devtmpfs_automount disklist helper_depmod helper_disableupdatedb helper_distro helper_network helper_xen kernelid label linodeid ramlimit rootdevicecustom rootdevicenum rootdevicero runlevel virt_mode )] ],
    },
    linode_disk => {
        create => [ [qw( label linodeid size type )], [qw( fromdistributionid isreadonly rootpass rootsshkey )] ],
        createfromdistribution => [ [qw( distributionid label linodeid rootpass size )], [ 'rootsshkey' ] ],
        createfromimage => [ [ 'imageid', 'linodeid' ], [qw( label rootpass rootsshkey size )] ],
        createfromstackscript => [ [qw( distributionid label linodeid rootpass size stackscriptid stackscriptudfresponses )], [ 'rootsshkey' ] ],
        delete => [ [ 'diskid', 'linodeid' ], [] ],
        duplicate => [ [ 'diskid', 'linodeid' ], [] ],
        imagize => [ [ 'diskid', 'linodeid' ], [ 'description', 'label' ] ],
        list => [ [ 'linodeid' ], [ 'diskid' ] ],
        resize => [ [qw( diskid linodeid size )], [] ],
        update => [ [ 'diskid' ], [qw( isreadonly label linodeid )] ],
    },
    linode_ip => {
        addprivate => [ [ 'linodeid' ], [] ],
        addpublic => [ [ 'linodeid' ], [] ],
        list => [ [], [ 'ipaddressid', 'linodeid' ] ],
        setrdns => [ [ 'hostname', 'ipaddressid' ], [] ],
        swap => [ [ 'ipaddressid' ], [ 'tolinodeid', 'withipaddressid' ] ],
    },
    linode_job => {
        list => [ [ 'linodeid' ], [ 'jobid', 'pendingonly' ] ],
    },
    nodebalancer => {
        create => [ [ 'datacenterid' ], [ 'clientconnthrottle', 'label' ] ],
        delete => [ [ 'nodebalancerid' ], [] ],
        list => [ [], [ 'nodebalancerid' ] ],
        update => [ [ 'nodebalancerid' ], [ 'clientconnthrottle', 'label' ] ],
    },
    nodebalancer_config => {
        create => [ [ 'nodebalancerid' ], [qw( algorithm check check_attempts check_body check_interval check_path check_timeout port protocol ssl_cert ssl_key stickiness )] ],
        delete => [ [ 'configid', 'nodebalancerid' ], [] ],
        list => [ [ 'nodebalancerid' ], [ 'configid' ] ],
        update => [ [ 'configid' ], [qw( algorithm check check_attempts check_body check_interval check_path check_timeout port protocol ssl_cert ssl_key stickiness )] ],
    },
    nodebalancer_node => {
        create => [ [qw( address configid label )], [ 'mode', 'weight' ] ],
        delete => [ [ 'nodeid' ], [] ],
        list => [ [ 'configid' ], [ 'nodeid' ] ],
        update => [ [ 'nodeid' ], [qw( address label mode weight )] ],
    },
    professionalservices_scope => {
        create => [ [], [qw( application_quantity content_management crossover current_provider customer_name database_server email_address linode_datacenter linode_plan mail_filtering mail_retrieval mail_transfer managed monitoring notes phone_number provider_access replication requested_service server_quantity system_administration ticket_number web_cache web_server webmail )] ],
    },
    stackscript => {
        create => [ [qw( distributionidlist label script )], [qw( description ispublic rev_note )] ],
        delete => [ [ 'stackscriptid' ], [] ],
        list => [ [], [ 'stackscriptid' ] ],
        update => [ [ 'stackscriptid' ], [qw( description distributionidlist ispublic label rev_note script )] ],
    },
    test => {
        echo => [ [], [] ],
    },
    user => {
        getapikey => [ [ 'password', 'username' ], [qw( expires label token )] ],
    },
};
# endvalidation

sub AUTOLOAD {
    ( my $name = $AUTOLOAD ) =~ s/.+:://;
    return if $name eq 'DESTROY';
    if ( $name =~ m/^(QUEUE_)?(.*?)_([^_]+)$/ ) {
        my ( $queue, $thing, $action ) = ( $1, $2, $3 );
        if ( exists $validation->{$thing} && exists $validation->{$thing}{$action} )
        {   no strict 'refs';
            *{$AUTOLOAD} = sub {
                my ( $self, %args ) = @_;
                for my $req ( @{ $validation->{$thing}{$action}[0] } ) {
                    if ( !exists $args{$req} ) {
                        carp
                            "Missing required argument $req for ${thing}_${action}";
                        return;
                    }
                }
                for my $given ( keys %args ) {
                    if (!first { $_ eq $given }
                        @{ $validation->{$thing}{$action}[0] },
                        @{ $validation->{$thing}{$action}[1] } )
                    {   carp "Unknown argument $given for ${thing}_${action}";
                        return;
                    }
                }
                ( my $apiAction = "${thing}_${action}" ) =~ s/_/./g;
                return $self->queue_request( api_action => $apiAction, %args ) if $queue;
                my $data = $self->do_request( api_action => $apiAction, %args );
                return [ map { $self->_lc_keys($_) } @$data ]
                    if ref $data eq 'ARRAY';
                return $self->_lc_keys($data) if ref $data eq 'HASH';
                return $data;
            };
            goto &{$AUTOLOAD};
        }
        else {
            carp "Can't call ${thing}_${action}";
            return;
        }
        return;
    }
    croak "Undefined subroutine \&$AUTOLOAD called";
}

sub send_queued_requests {
    my $self = shift;
    my $items = shift;

    if ( $self->list_queue == 0 ) {
        $self->_error( -1, "No queued items to send" );
        return;
    }

    my @responses;
    for my $data ( $self->process_queue( $items ) ) {
        if ( ref $data eq 'ARRAY' ) {
            push @responses, [ map { $self->_lc_keys($_) } @$data ];
        } elsif( ref $data eq 'HASH' ) {
            push @responses, $self->_lc_keys($data);
        } else {
            push @responses, $data;
        }
    }

    return @responses;
}

'mmm, cake';
__END__

=head1 NAME

WebService::Linode - Perl Interface to the Linode.com API.

=head1 SYNOPSIS

    my $api = WebService::Linode->new( apikey => 'your api key here');
    print Dumper($api->linode_list);
    $api->linode_reboot(linodeid=>242);

This module implements the Linode.com api methods.  Linode methods have had
dots replaced with underscores to generate the perl method name.  All keys
and parameters have been lower cased but returned data remains otherwise the
same.  For additional information see L<http://www.linode.com/api/>

=head1 Constructor

For documentation of possible arguments to the constructor, see
L<WebService::Linode::Base>.

=head1 Batch requests

Each of the Linode API methods below may optionally be prefixed with QUEUE_
to add that request to a queue to be processed later in one or more batch
requests which can be processed by calling send_queued_requests.
For example:

    my @linode_ids = () # Get your linode ids through normal methods
    my @responses = map { $api->linode_ip_list( linodeid=>$_ ) } @linode_ids;

Can be reduced to a single request:

    my @linode_ids = () # Get your linode ids through normal methods
    $api->QUEUE_linode_ip_list( linodeid=>$_ ) for @linode_ids;
    my @responses = $api->send_queued_requests; # One api request

See L<WebService::Linode::Base> for additional queue management methods.

=head3 send_queued_requests

Send queued batch requests, returns list of responses.

=head1 Methods from the Linode API

=for autogen

=head2 account Methods

=head3 account_estimateinvoice

Estimates the invoice for adding a new Linode or NodeBalancer as well as resizing a Linode. This returns two fields: PRICE which is the estimated cost of the invoice, and INVOICE_TO which is the date invoice would be though with timezone set to America/New_York

Required Parameters:

=over 4

=item * mode

This is one of the following options: 'linode_new', 'linode_resize', or 'nodebalancer_new'.

=back

Optional Parameters:

=over 4

=item * planid

The desired PlanID available from avail.LinodePlans(). This is required for modes 'linode_new' and 'linode_resize'.

=item * paymentterm

Subscription term in months. One of: 1, 12, or 24. This is required for modes 'linode_new' and 'nodebalancer_new'.

=item * linodeid

This is the LinodeID you want to resize and is required for mode 'linode_resize'.

=back

=head3 account_info

Shows information about your account such as the date your account was opened as well as your network utilization for the current month in gigabytes.

=head3 account_paybalance

Pays current balance on file, returning it in the response.

=head3 account_updatecard

Required Parameters:

=over 4

=item * ccnumber

=item * ccexpyear

=item * ccexpmonth

=back

=head2 avail Methods

=head3 avail_datacenters

Returns a list of Linode data center facilities.

=head3 avail_distributions

Returns a list of available Linux Distributions.

Optional Parameters:

=over 4

=item * distributionid

Limits the results to the specified DistributionID

=back

=head3 avail_kernels

List available kernels.

Optional Parameters:

=over 4

=item * isxen

Limits the results to show only Xen kernels

=item * kernelid

=back

=head3 avail_linodeplans

Returns a structure of Linode PlanIDs containing the Plan label and the availability in each Datacenter.

Optional Parameters:

=over 4

=item * planid

Limits the list to the specified PlanID

=back

=head3 avail_nodebalancers

Returns NodeBalancer pricing information.

=head3 avail_stackscripts

Returns a list of available public StackScripts.

Optional Parameters:

=over 4

=item * keywords

Search terms

=item * distributionid

Limit the results to StackScripts that can be applied to this DistributionID

=item * distributionvendor

Debian, Ubuntu, Fedora, etc.

=back

=head2 domain Methods

=head3 domain_create

Create a domain record.

Required Parameters:

=over 4

=item * domain

The zone's name

=item * type

master or slave

=back

Optional Parameters:

=over 4

=item * status

0, 1, or 2 (disabled, active, edit mode)

=item * ttl_sec

=item * expire_sec

=item * master_ips

When type=slave, the zone's master DNS servers list, semicolon separated

=item * lpm_displaygroup

Display group in the Domain list inside the Linode DNS Manager

=item * refresh_sec

=item * soa_email

Required when type=master

=item * axfr_ips

IP addresses allowed to AXFR the entire zone, semicolon separated

=item * retry_sec

=item * description

Currently undisplayed.

=back

=head3 domain_delete

Required Parameters:

=over 4

=item * domainid

=back

=head3 domain_list

Lists domains you have access to.

Optional Parameters:

=over 4

=item * domainid

Limits the list to the specified DomainID

=back

=head3 domain_update

Update a domain record.

Required Parameters:

=over 4

=item * domainid

=back

Optional Parameters:

=over 4

=item * status

0, 1, or 2 (disabled, active, edit mode)

=item * domain

The zone's name

=item * ttl_sec

=item * expire_sec

=item * type

master or slave

=item * soa_email

Required when type=master

=item * refresh_sec

=item * lpm_displaygroup

Display group in the Domain list inside the Linode DNS Manager

=item * master_ips

When type=slave, the zone's master DNS servers list, semicolon separated

=item * axfr_ips

IP addresses allowed to AXFR the entire zone, semicolon separated

=item * retry_sec

=item * description

Currently undisplayed.

=back

=head2 domain_resource Methods

=head3 domain_resource_create

Create a domain record.

Required Parameters:

=over 4

=item * domainid

=item * type

One of: NS, MX, A, AAAA, CNAME, TXT, or SRV

=back

Optional Parameters:

=over 4

=item * target

When Type=MX the hostname.  When Type=CNAME the target of the alias.  When Type=TXT the value of the record. When Type=A or AAAA the token of '[remote_addr]' will be substituted with the IP address of the request.

=item * ttl_sec

TTL.  Leave as 0 to accept our default.

=item * port

=item * weight

=item * priority

Priority for MX and SRV records, 0-255

=item * protocol

The protocol to append to an SRV record.  Ignored on other record types.

=item * name

The hostname or FQDN.  When Type=MX the subdomain to delegate to the Target MX server.

=back

=head3 domain_resource_delete

Required Parameters:

=over 4

=item * resourceid

=item * domainid

=back

=head3 domain_resource_list

Required Parameters:

=over 4

=item * domainid

=back

Optional Parameters:

=over 4

=item * resourceid

=back

=head3 domain_resource_update

Update a domain record.

Required Parameters:

=over 4

=item * resourceid

=back

Optional Parameters:

=over 4

=item * target

When Type=MX the hostname.  When Type=CNAME the target of the alias.  When Type=TXT the value of the record. When Type=A or AAAA the token of '[remote_addr]' will be substituted with the IP address of the request.

=item * domainid

=item * ttl_sec

TTL.  Leave as 0 to accept our default.

=item * port

=item * weight

=item * protocol

The protocol to append to an SRV record.  Ignored on other record types.

=item * priority

Priority for MX and SRV records, 0-255

=item * name

The hostname or FQDN.  When Type=MX the subdomain to delegate to the Target MX server.

=back

=head2 linode Methods

=head3 linode_boot

Issues a boot job for the provided ConfigID.  If no ConfigID is provided boots the last used configuration profile, or the first configuration profile if this Linode has never been booted.

Required Parameters:

=over 4

=item * linodeid

=back

Optional Parameters:

=over 4

=item * configid

The ConfigID to boot, available from linode.config.list().

=back

=head3 linode_clone

Creates a new Linode, assigns you full privileges, and then clones the specified LinodeID to the new Linode. There is a limit of 5 active clone operations per source Linode.  It is recommended that the source Linode be powered down during the clone.

Required Parameters:

=over 4

=item * planid

The desired PlanID available from avail.LinodePlans()

=item * linodeid

The LinodeID that you want cloned

=item * datacenterid

The DatacenterID from avail.datacenters() where you wish to place this new Linode

=back

Optional Parameters:

=over 4

=item * paymentterm

Subscription term in months for prepaid customers.  One of: 1, 12, or 24

=item * hypervisor

=back

=head3 linode_create

Creates a Linode and assigns you full privileges. There is a 75-linodes-per-hour limiter.

Required Parameters:

=over 4

=item * planid

The desired PlanID available from avail.LinodePlans()

=item * datacenterid

The DatacenterID from avail.datacenters() where you wish to place this new Linode

=back

Optional Parameters:

=over 4

=item * paymentterm

Subscription term in months for prepaid customers.  One of: 1, 12, or 24

=back

=head3 linode_delete

Immediately removes a Linode from your account and issues a pro-rated credit back to your account, if applicable.  To prevent accidental deletes, this requires the Linode has no Disk images.  You must first delete its disk images."

Required Parameters:

=over 4

=item * linodeid

The LinodeID to delete

=back

Optional Parameters:

=over 4

=item * skipchecks

Skips the safety checks and will always delete the Linode

=back

=head3 linode_list

Returns a list of all Linodes user has access or delete to, including some properties.  Status values are -1: Being Created, 0: Brand New, 1: Running, and 2: Powered Off.

Optional Parameters:

=over 4

=item * linodeid

Limits the list to the specified LinodeID

=back

=head3 linode_mutate

Upgrades a Linode to its next generation.

Required Parameters:

=over 4

=item * linodeid

=back

=head3 linode_reboot

Issues a shutdown, and then boot job for a given LinodeID.

Required Parameters:

=over 4

=item * linodeid

=back

Optional Parameters:

=over 4

=item * configid

=back

=head3 linode_resize

Resizes a Linode from one plan to another.  Immediately shuts the Linode down, charges/credits the account, and issue a migration to another host server.

Required Parameters:

=over 4

=item * planid

The desired PlanID available from avail.LinodePlans()

=item * linodeid

=back

=head3 linode_shutdown

Issues a shutdown job for a given LinodeID.

Required Parameters:

=over 4

=item * linodeid

=back

=head3 linode_update

Updates a Linode's properties.

Required Parameters:

=over 4

=item * linodeid

=back

Optional Parameters:

=over 4

=item * alert_bwquota_threshold

Percentage of monthly bw quota

=item * alert_bwin_threshold

Mb/sec

=item * alert_cpu_threshold

CPU Alert threshold, percentage 0-800

=item * label

This Linode's label

=item * ms_ssh_port

=item * lpm_displaygroup

Display group in the Linode list inside the Linode Manager

=item * alert_bwin_enabled

Enable the incoming bandwidth email alert

=item * ms_ssh_disabled

=item * backupwindow

=item * alert_cpu_enabled

Enable the cpu usage email alert

=item * backupweeklyday

=item * alert_diskio_enabled

Enable the disk IO email alert

=item * ms_ssh_ip

=item * alert_bwquota_enabled

Enable the bw quote email alert

=item * ms_ssh_user

=item * watchdog

Enable the Lassie shutdown watchdog

=item * alert_bwout_enabled

Enable the outgoing bandwidth email alert

=item * alert_bwout_threshold

Mb/sec

=item * alert_diskio_threshold

IO ops/sec

=back

=head3 linode_webconsoletoken

Generates a console token starting a web console LISH session for the requesting IP

Required Parameters:

=over 4

=item * linodeid

=back

=head2 linode_config Methods

=head3 linode_config_create

Creates a Linode Configuration Profile.

Required Parameters:

=over 4

=item * linodeid

=item * label

The Label for this profile

=item * disklist

A comma delimited list of DiskIDs; position reflects device node.  The 9th element for specifying the initrd.

=item * kernelid

The KernelID for this profile.  Found in avail.kernels()

=back

Optional Parameters:

=over 4

=item * comments

Comments you wish to save along with this profile

=item * rootdevicero

Enables the 'ro' kernel flag.  Modern distros want this.

=item * virt_mode

Controls the virtualization mode. One of 'paravirt', 'fullvirt'

=item * rootdevicenum

Which device number (1-8) that contains the root partition.  0 to utilize RootDeviceCustom.

=item * ramlimit

RAMLimit in MB.  0 for max.

=item * helper_xen

Deprecated - use helper_distro.

=item * rootdevicecustom

A custom root device setting.

=item * devtmpfs_automount

Controls if pv_ops kernels should automount devtmpfs at boot.

=item * helper_distro

Enable the Distro filesystem helper.  Corrects fstab and inittab/upstart entries depending on the kernel you're booting.  You want this.

=item * helper_depmod

Creates an empty modprobe file for the kernel you're booting.

=item * helper_network

Automatically creates network configuration files for your distro and places them into your filesystem.

=item * helper_disableupdatedb

Enable the disableUpdateDB filesystem helper

=item * runlevel

One of 'default', 'single', 'binbash'

=back

=head3 linode_config_delete

Deletes a Linode Configuration Profile.

Required Parameters:

=over 4

=item * configid

=item * linodeid

=back

=head3 linode_config_list

Lists a Linode's Configuration Profiles.

Required Parameters:

=over 4

=item * linodeid

=back

Optional Parameters:

=over 4

=item * configid

=back

=head3 linode_config_update

Updates a Linode Configuration Profile.

Required Parameters:

=over 4

=item * configid

=back

Optional Parameters:

=over 4

=item * comments

Comments you wish to save along with this profile

=item * linodeid

=item * rootdevicero

Enables the 'ro' kernel flag.  Modern distros want this.

=item * label

The Label for this profile

=item * virt_mode

Controls the virtualization mode. One of 'paravirt', 'fullvirt'

=item * rootdevicenum

Which device number (1-8) that contains the root partition.  0 to utilize RootDeviceCustom.

=item * disklist

A comma delimited list of DiskIDs; position reflects device node.  The 9th element for specifying the initrd.

=item * kernelid

The KernelID for this profile.  Found in avail.kernels()

=item * ramlimit

RAMLimit in MB.  0 for max.

=item * helper_xen

Deprecated - use helper_distro.

=item * rootdevicecustom

A custom root device setting.

=item * devtmpfs_automount

Controls if pv_ops kernels should automount devtmpfs at boot.

=item * helper_distro

Enable the Distro filesystem helper.  Corrects fstab and inittab/upstart entries depending on the kernel you're booting.  You want this.

=item * helper_depmod

Creates an empty modprobe file for the kernel you're booting.

=item * helper_network

Automatically creates network configuration files for your distro and places them into your filesystem.

=item * helper_disableupdatedb

Enable the disableUpdateDB filesystem helper

=item * runlevel

One of 'default', 'single', 'binbash'

=back

=head2 linode_disk Methods

=head3 linode_disk_create

Required Parameters:

=over 4

=item * linodeid

=item * label

The display label for this Disk

=item * type

The formatted type of this disk.  Valid types are: ext3, ext4, swap, raw

=item * size

The size in MB of this Disk.

=back

Optional Parameters:

=over 4

=item * rootsshkey

=item * fromdistributionid

=item * rootpass

=item * isreadonly

Enable forced read-only for this Disk

=back

=head3 linode_disk_createfromdistribution

Required Parameters:

=over 4

=item * size

Size of this disk image in MB

=item * rootpass

The root user's password

=item * linodeid

=item * distributionid

The DistributionID to create this disk from.  Found in avail.distributions()

=item * label

The label of this new disk image

=back

Optional Parameters:

=over 4

=item * rootsshkey

Optionally sets this string into /root/.ssh/authorized_keys upon distribution configuration.

=back

=head3 linode_disk_createfromimage

Creates a new disk from a previously imagized disk.

Required Parameters:

=over 4

=item * imageid

The ID of the frozen image to deploy from

=item * linodeid

Specifies the Linode to deploy on to

=back

Optional Parameters:

=over 4

=item * rootsshkey

Optionally sets this string into /root/.ssh/authorized_keys upon image deployment

=item * rootpass

Optionally sets the root password at deployment time. If a password is not provided the existing root password of the frozen image will not be modified

=item * label

The label of this new disk image

=item * size

The size of the disk image to creates. Defaults to the minimum size required for the requested image

=back

=head3 linode_disk_createfromstackscript

Required Parameters:

=over 4

=item * linodeid

=item * stackscriptudfresponses

JSON encoded name/value pairs, answering this StackScript's User Defined Fields

=item * label

The label of this new disk image

=item * size

Size of this disk image in MB

=item * distributionid

Which Distribution to apply this StackScript to.  Must be one from the script's DistributionIDList

=item * rootpass

The root user's password

=item * stackscriptid

The StackScript to create this image from

=back

Optional Parameters:

=over 4

=item * rootsshkey

Optionally sets this string into /root/.ssh/authorized_keys upon distribution configuration.

=back

=head3 linode_disk_delete

Required Parameters:

=over 4

=item * diskid

=item * linodeid

=back

=head3 linode_disk_duplicate

Performs a bit-for-bit copy of a disk image.

Required Parameters:

=over 4

=item * diskid

=item * linodeid

=back

=head3 linode_disk_imagize

Creates a gold-master image for future deployments

Required Parameters:

=over 4

=item * diskid

Specifies the source Disk to create the image from

=item * linodeid

Specifies the source Linode to create the image from

=back

Optional Parameters:

=over 4

=item * description

An optional description of the created image

=item * label

Sets the name of the image shown in the base image list, defaults to the source image label

=back

=head3 linode_disk_list

Status values are 1: Ready and 2: Being Deleted.

Required Parameters:

=over 4

=item * linodeid

=back

Optional Parameters:

=over 4

=item * diskid

=back

=head3 linode_disk_resize

Required Parameters:

=over 4

=item * diskid

=item * linodeid

=item * size

The requested new size of this Disk in MB

=back

=head3 linode_disk_update

Required Parameters:

=over 4

=item * diskid

=back

Optional Parameters:

=over 4

=item * linodeid

=item * isreadonly

Enable forced read-only for this Disk

=item * label

The display label for this Disk

=back

=head2 linode_ip Methods

=head3 linode_ip_addprivate

Assigns a Private IP to a Linode.  Returns the IPAddressID that was added.

Required Parameters:

=over 4

=item * linodeid

=back

=head3 linode_ip_addpublic

Assigns a Public IP to a Linode.  Returns the IPAddressID and IPAddress that was added.

Required Parameters:

=over 4

=item * linodeid

The LinodeID of the Linode that will be assigned an additional public IP address

=back

=head3 linode_ip_list

Returns the IP addresses of all Linodes you have access to.

Optional Parameters:

=over 4

=item * linodeid

If specified, limits the result to this LinodeID

=item * ipaddressid

If specified, limits the result to this IPAddressID

=back

=head3 linode_ip_setrdns

Sets the rDNS name of a Public IP.  Returns the IPAddressID and IPAddress that were updated.

Required Parameters:

=over 4

=item * hostname

The hostname to set the reverse DNS to

=item * ipaddressid

The IPAddressID of the address to update

=back

=head3 linode_ip_swap

Exchanges Public IP addresses between two Linodes within a Datacenter.  The destination of the IP Address can be designated by either the toLinodeID or withIPAddressID parameter.  Returns the resulting relationship of the Linode and IP Address parameters.  When performing a one directional swap, the source is represented by the first of the two resultant array members.

Required Parameters:

=over 4

=item * ipaddressid

The IPAddressID of an IP Address to transfer or swap

=back

Optional Parameters:

=over 4

=item * tolinodeid

The LinodeID of the Linode where IPAddressID will be transfered

=item * withipaddressid

The IP Address ID to swap

=back

=head2 linode_job Methods

=head3 linode_job_list

Required Parameters:

=over 4

=item * linodeid

=back

Optional Parameters:

=over 4

=item * pendingonly

=item * jobid

Limits the list to the specified JobID

=back

=head2 stackscript Methods

=head3 stackscript_create

Create a StackScript.

Required Parameters:

=over 4

=item * script

The actual script

=item * distributionidlist

Comma delimited list of DistributionIDs that this script works on

=item * label

The Label for this StackScript

=back

Optional Parameters:

=over 4

=item * rev_note

=item * description

=item * ispublic

Whether this StackScript is published in the Library, for everyone to use

=back

=head3 stackscript_delete

Required Parameters:

=over 4

=item * stackscriptid

=back

=head3 stackscript_list

Lists StackScripts you have access to.

Optional Parameters:

=over 4

=item * stackscriptid

Limits the list to the specified StackScriptID

=back

=head3 stackscript_update

Update a StackScript.

Required Parameters:

=over 4

=item * stackscriptid

=back

Optional Parameters:

=over 4

=item * script

The actual script

=item * rev_note

=item * ispublic

Whether this StackScript is published in the Library, for everyone to use

=item * label

The Label for this StackScript

=item * description

=item * distributionidlist

Comma delimited list of DistributionIDs that this script works on

=back

=head2 nodeblancer Methods

=head2 nodebalancer_config Methods

=head3 nodebalancer_config_create

Required Parameters:

=over 4

=item * nodebalancerid

The parent NodeBalancer's ID

=back

Optional Parameters:

=over 4

=item * check_path

When check=http, the path to request

=item * ssl_cert

SSL certificate served by the NodeBalancer when the protocol is 'https'

=item * check_body

When check=http, a regex to match within the first 16,384 bytes of the response body

=item * stickiness

Session persistence.  One of 'none', 'table', 'http_cookie'

=item * port

Port to bind to on the public interfaces. 1-65534

=item * check_timeout

Seconds to wait before considering the probe a failure. 1-30.  Must be less than check_interval.

=item * check

Perform active health checks on the backend nodes.  One of 'connection', 'http', 'http_body'

=item * check_attempts

Number of failed probes before taking a node out of rotation. 1-30

=item * ssl_key

Unpassphrased private key for the SSL certificate when protocol is 'https'

=item * check_interval

Seconds between health check probes.  2-3600

=item * protocol

Either 'tcp', 'http', or 'https'

=item * algorithm

Balancing algorithm.  One of 'roundrobin', 'leastconn', 'source'

=back

=head3 nodebalancer_config_delete

Deletes a NodeBalancer's Config

Required Parameters:

=over 4

=item * configid

The ConfigID to delete

=item * nodebalancerid

=back

=head3 nodebalancer_config_list

Returns a list of NodeBalancers this user has access or delete to, including their properties

Required Parameters:

=over 4

=item * nodebalancerid

=back

Optional Parameters:

=over 4

=item * configid

Limits the list to the specified ConfigID

=back

=head3 nodebalancer_config_update

Updates a Config's properties

Required Parameters:

=over 4

=item * configid

=back

Optional Parameters:

=over 4

=item * check_path

When check=http, the path to request

=item * ssl_cert

SSL certificate served by the NodeBalancer when the protocol is 'https'

=item * check_body

When check=http, a regex to match within the first 16,384 bytes of the response body

=item * stickiness

Session persistence.  One of 'none', 'table', 'http_cookie'

=item * port

Port to bind to on the public interfaces. 1-65534

=item * check_timeout

Seconds to wait before considering the probe a failure. 1-30.  Must be less than check_interval.

=item * check

Perform active health checks on the backend nodes.  One of 'connection', 'http', 'http_body'

=item * check_attempts

Number of failed probes before taking a node out of rotation. 1-30

=item * ssl_key

Unpassphrased private key for the SSL certificate when protocol is 'https'

=item * check_interval

Seconds between health check probes.  2-3600

=item * protocol

Either 'tcp', 'http', or 'https'

=item * algorithm

Balancing algorithm.  One of 'roundrobin', 'leastconn', 'source'

=back

=head2 nodebalancer_node Methods

=head3 nodebalancer_node_create

Required Parameters:

=over 4

=item * configid

The parent ConfigID to attach this Node to

=item * address

The address:port combination used to communicate with this Node

=item * label

This backend Node's label

=back

Optional Parameters:

=over 4

=item * mode

The connections mode for this node.  One of 'accept', 'reject', or 'drain'

=item * weight

Load balancing weight, 1-255. Higher means more connections.

=back

=head3 nodebalancer_node_delete

Deletes a Node from a NodeBalancer Config

Required Parameters:

=over 4

=item * nodeid

The NodeID to delete

=back

=head3 nodebalancer_node_list

Returns a list of Nodes associated with a NodeBalancer Config

Required Parameters:

=over 4

=item * configid

=back

Optional Parameters:

=over 4

=item * nodeid

Limits the list to the specified NodeID

=back

=head3 nodebalancer_node_update

Updates a Node's properties

Required Parameters:

=over 4

=item * nodeid

=back

Optional Parameters:

=over 4

=item * address

The address:port combination used to communicate with this Node

=item * mode

The connections mode for this node.  One of 'accept', 'reject', or 'drain'

=item * weight

Load balancing weight, 1-255. Higher means more connections.

=item * label

This backend Node's label

=back

=head2 user Methods

=head3 user_getapikey

Authenticates a Linode Manager user against their username, password, and two-factor token (when enabled), and then returns a new API key, which can be used until it expires.  The number of active keys is limited to 20.

Required Parameters:

=over 4

=item * password

=item * username

=back

Optional Parameters:

=over 4

=item * label

An optional label for this key.

=item * token

Required when two-factor authentication is enabled.

=item * expires

Number of hours the key will remain valid, between 0 and 8760. 0 means no expiration. Defaults to 168.

=back

=head2 image Methods

=head3 image_delete

Deletes a gold-master image

Required Parameters:

=over 4

=item * imageid

The ID of the gold-master image to delete

=back

=head3 image_list

Lists available gold-master images

Optional Parameters:

=over 4

=item * imageid

Request information for a specific gold-master image

=item * pending

Show images currently being created.

=back

=head3 image_update

Update an Image record.

Required Parameters:

=over 4

=item * imageid

The ID of the Image to modify.

=back

Optional Parameters:

=over 4

=item * label

The label of the Image.

=item * description

An optional description of the Image.

=back

=head2 professionalservices_scope Methods

=head3 professionalservices_scope_create

Creates a new Professional Services scope submission

Optional Parameters:

=over 4

=item * ticket_number

=item * server_quantity

How many separate servers are involved in this migration?

=item * mail_filtering

Services here manipulate recieved messages in various ways

=item * database_server

Generally used by applications to provide an organized way to capture and manipulate data

=item * current_provider

=item * web_cache

Caching mechanisms provide temporary storage for web requests--cached content can generally be retrieved faster.

=item * mail_transfer

Mail transfer agents facilitate message transfer between servers

=item * application_quantity

How many separate applications or websites are involved in this migration?

=item * email_address

=item * crossover

These can assist in providing reliable crossover--failures of individual components can be transparent to the application.

=item * web_server

These provide network protocol handling for hosting websites.

=item * replication

Redundant services often have shared state--replication automatically propagates state changes between individual components.

=item * provider_access

What types of server access do you have at your current provider?

=item * webmail

Access and administrate mail via web interfaces

=item * phone_number

=item * content_management

Centralized interfaces for editing, organizing, and publishing content

=item * mail_retrieval

User mail clients connect to these to retrieve delivered mail

=item * managed

=item * requested_service

=item * monitoring

Constant monitoring of your deployed systems--these can also provide automatic notifications for service failures.

=item * notes

=item * linode_datacenter

Which datacenters would you like your Linodes to be deployed in?

=item * customer_name

=item * linode_plan

Which Linode plans would you like to deploy?

=item * system_administration

Various web interfaces for performing system administration tasks

=back

=for endautogen

=head1 AUTHORS

=over

=item * Michael Greb, C<< <michael@thegrebs.com> >>

=item * Stan "The Man" Schwertly C<< <stan@schwertly.com> >>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008-2014 Michael Greb, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

