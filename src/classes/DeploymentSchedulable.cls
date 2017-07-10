global class DeploymentSchedulable implements Schedulable {
    global void execute(SchedulableContext context) {
        DeploymentService.deploy('a00i000000dniLx', 'a03i000000O3aRP');
    }
}